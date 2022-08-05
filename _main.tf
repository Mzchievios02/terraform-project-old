resource  "aws_instance" "webserver" {
    ami                     = "ami-08d4ac5b634553e16" 
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.webserver-sg.id]
    
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
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
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# amazon linux ami-090fa75af13c156b4
# ubuntu 20.04 ami-08d4ac5b634553e16