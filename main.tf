terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  access_key = "Write your own access key here"
  secret_key = "Write your own secret key here"
}

# Project breakdown:

# 1) Create VPC

resource "aws_vpc" "vpc_web" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "Production Web-Server"
  }
}

# 2) Create Internet Gateway

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc_web.id

  tags = {
    Name = "prod vpc"
  }
}

# 3) Create Custom Route Table

resource "aws_route_table" "routeTable" {
  vpc_id = aws_vpc.vpc_web.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "prod route table"
  }
}

# 4) Create a Subnet

resource "aws_subnet" "subnet_prod-vpc" {
  vpc_id     = aws_vpc.vpc_web.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Subnet for web server"
  }
}


# 5) Associate Subnet with Route Table

resource "aws_route_table_association" "rt-assoc" {
  subnet_id      = aws_subnet.subnet_prod-vpc.id
  route_table_id = aws_route_table.routeTable.id
}


# 6) Create Security group to allow port 22, 80, 443

resource "aws_security_group" "sc_web" {
  name        = "allow_web"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc_web.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Any protocol
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow web traffic"
  }
}

# 7) Create Network Interface with an IP in the subnet that was created in step4

resource "aws_network_interface" "prod_interface" {
  subnet_id       = aws_subnet.subnet_prod-vpc.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.sc_web.id]
}

# 8) Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.prod_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.ig]
}

# 9) Create Ubuntu server and install/enable apache2

resource "aws_instance" "web_server_instance" {
  ami           = "ami-00399ec92321828f5"
  instance_type = "t2.micro"
  availability_zone = "us-east-2a"
  key_name = "main-key"
  network_interface {
    network_interface_id = aws_network_interface.prod_interface.id
    device_index         = 0
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "Web Server"
  }
}