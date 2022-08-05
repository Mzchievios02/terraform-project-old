resource  "aws_instance" "webserver" {
    ami                     = "ami-08d4ac5b634553e16" 
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.webserver-sg.id]
    
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.webserver_port} &
                EOF
    
    user_data_replace_on_change = true

    tags = {
        Name = "simple-webserver"
        ManagedBy = "Terraform"

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

variable "webserver_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 8080
}

# amazon linux ami-090fa75af13c156b4
# ubuntu 20.04 ami-08d4ac5b634553e16