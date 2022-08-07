resource  "aws_launch_configuration" "webserver" {
    image_id                = "ami-08d4ac5b634553e16" 
    instance_type           = "t2.micro"
    security_groups         = [aws_security_group.webserver-sg.id]
    
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.webserver_port} &
                EOF

    # Required when using a launch configuration with an auto scaling group.
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "webserver" {
    launch_configuration = aws_launch_configuration.webserver.name
    vpc_zone_identifier = data.aws_subnets.default.vpc_security_group_ids

    target_group_arns   = [aws_lb_target_group.asg.arn] 
    health_check_type   = "ELB" 

    min_size = 1
    max_size = 2

    tag {
      key                 = "Name"
      value               = "simple-webserver-asg" 
      propagate_at_launch = true
    }  
  
}

resource "aws_security_group" "webserver-sg" {
    name            = "simple-webserver-sg"

    ingress {
        from_port   = var.webserver_port
        to_port     = var.webserver_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "elb" {
    name                = "terraform-asg"
    load_balancer_type  = "application"
    subnets             = data.aws_subnets.default.ids
    security_groups     = [aws_security_group.alb.id] 
  
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.elb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "fixed-response"

      fixed_response {
        content_type  = "text/plain"
        message_body  = "404: page not found"
        status_code   = 404
      }
    }
}

resource "aws_lb_target_group" "asg" {
    name        = "terraform-tg"
    port        = var.webserver_port
    protocol    = "HTTP"
    vpc_id      = data.aws_vpc.default.id   

    health_check {
      path                = "/"
      protocol            = "HTTP"
      matcher             = 200
      interval            = 15
      timeout             = 3
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
}

resource "aws_security_group" "alb" {
    name = "alb"

    # Allow inbound HTTP requests
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow all outbound requests
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_lb_listener_rule" "asg" {
    listener_arn   = aws_lb_listener.http.arn
    priority       = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }
  
    action {
      type             = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
    }   
}

variable "webserver_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 8080
}

data "aws_vpc" "default" {
    default = true
}
data "aws_subnets" "default" {
    filter {
      name   = "vpc-id" 
      values = [data.aws_vpc.default.id]
    }
  
}
output "alb_dns_name" {
    value       = aws_lb.elb.dns_name
    description = "The domain name of the load balancer" 
}