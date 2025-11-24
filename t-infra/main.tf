# 1. Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # This is needed for the aws_key_pair
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1" # Your preferred region
}

# --- 1. Create Network (VPC) ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "exxomm-vpc"
  }
}


# 2. --- Create Subnets (subnets in the VPC) ---
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "exxomm-subnet"
  }
}

# 3. --- Set up "Internet Access" ---
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}


# 4. --- Create "Route Table" to allow internet access ---
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


# 5.  --- Define Security Groups (Firewalls) ---
#5a.   -- Security Group for Reverse Proxy Server --
resource "aws_security_group" "allow-reverse-proxy" {
  name        = "allow-reverse-proxy-sg"
  description = "Allows the public traffic to only the reverse proxy server"
  vpc_id      = aws_vpc.main.id


  #Allow HTTP from ANYWHERE (This is the entry point for users)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (for you to install Nginx)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Ideally, replace with your My IP
  }

  # Allow outbound traffic (to talk to Frontend/Backend)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


# 5b. --- Security Group for Web/App Servers ---
resource "aws_security_group" "allow_web" {
  name   = "allow_web_traffic"
  vpc_id = aws_vpc.main.id

  # Allow ICMP from anywhere for Nagios ping checks
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP (port 80) from anywhere for your frontend
  ingress {
    from_port       = 3000 # Frontend runs here
    to_port         = 8000 # Backend runs here
    protocol        = "tcp"
    security_groups = [aws_security_group.allow-reverse-proxy.id]
  }

  # Allow Traffic from NAGIOS SERVER
  ingress {
    from_port       = 3000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_nagios.id]
  }

  # Allow SSH (port 22) from your IP so Ansible can connect
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # WARNING: 0.0.0.0/0 is insecure. Replace with your IP.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# 5c. --- Security Group for Nagios Server (Monitoring) ---
resource "aws_security_group" "allow_nagios" {
  name   = "allow_nagios_web"
  vpc_id = aws_vpc.main.id

  # Allow ICMP from anywhere for Nagios ping checks
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  # Allow HTTP (port 80) from your IP to see the dashboard
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    # WARNING: 0.0.0.0/0 is insecure. Replace with your IP.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22) from your IP so Ansible can connect
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    # WARNING: 0.0.0.0/0 is insecure. Replace with your IP.
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 6. --- Find the latest Ubuntu AMI ---
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
  owners = ["099720109477"]
}


# 7. --- Create the EC2 Instances ---
#7a.    -- Frontend Instance --
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro" # Kept your change
  key_name                    = "exxomm-key"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true

  tags = {
    Name = "Exxomm-Frontend"
    Role = "frontend"
  }
}

#7b. --- Backend Instance ---
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro" # Kept your change
  key_name                    = "exxomm-key"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true

  tags = {
    Name = "Exxomm-Backend"
    Role = "backend"
  }
}

# 7c. --- Nagios Instance ---
resource "aws_instance" "nagios_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # t2.micro is fine for Nagios
  key_name      = "exxomm-key"

  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_nagios.id]
  associate_public_ip_address = true

  tags = {
    Name = "Exxomm-Nagios-Server"
    Role = "monitoring"
  }
}

# 7d. --- Nginx Reverse Proxy Instance ---
resource "aws_instance" "nginx-reverse-proxy" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = "exxomm-key"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow-reverse-proxy.id]
  associate_public_ip_address = true
  tags = {
    Name = "exxomm-reverse-proxy"
    Role = "reverse-proxy"
  }
}


# 8. --- Elastic IP for the Proxy Server ---
resource "aws_eip" "proxy_eip" {
  instance = aws_instance.nginx-reverse-proxy.id
  domain   = "vpc"
  
  tags = {
    Name = "Exxomm-Proxy-EIP"
  }
}

# 9. --- Output the IP so that I can see it easily ---
output "proxy_elastic_ip" {
  value = aws_eip.proxy_eip.public_ip
}




