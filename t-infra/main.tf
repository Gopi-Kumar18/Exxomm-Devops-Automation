# 1. Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Your preferred region
}

# 2. Create Your Network (VPC)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "exxomm-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "exxomm-subnet"
  }
}

# 3. Set up Internet Access
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # All traffic
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# 4. Define Security Groups (Firewalls)
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP (port 80) from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22) from your IP so Ansible can connect
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Your IP address
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. --- NEW --- Find the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical's official owner ID
  owners = ["099720109477"] 
}

# 6. --- UPDATED --- Create the EC2 Instances
resource "aws_instance" "frontend" {
  # Use the AMI we just found
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "exxomm-key"
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  associate_public_ip_address = true 

  tags = {
    Name    = "Exxomm-Frontend"
    Role    = "frontend" # <-- Critical for Ansible
  }
}

resource "aws_instance" "backend" {
  # Use the *same* AMI
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "exxomm-key"
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  associate_public_ip_address = true

  tags = {
    Name    = "Exxomm-Backend"
    Role    = "backend" # <-- Critical for Ansible
  }
}