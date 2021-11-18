# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAV3EUPNTH26URKMWB"
  secret_key = "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"
}

#resource "aws_instance" "foobarweb" {
#  ami           = "ami-0747bdcabd34c712a"
#  instance_type = "t2.micro"  
#  tags = {
#    Name = "Hello Foo"
#  }

#}

# 1.Create a VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

#2.Create Internet Gateway
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "Prod Gateway"
  }
}

#3.Create Custom Route Table (optional but cool to look at)
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    #The 0.0.0.0/0 means that, send all IPv4 traffic to this route id
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.prod-gw.id
  }

  tags = {
    Name = "Prod route table"
  }
}

#4.Create a Subnet where our webserver is going to reside on
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#5.Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


#6.Create security group to allow port 22(SSH), 80(http), 443 (https)
resource "aws_security_group" "prod_allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  #Any IP address since it's web/https for public, if it was for specific ip we do "1.1.1.1/32"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  #Any IP address since it's web/https for public, if it was for specific ip we do "1.1.1.1/32"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  #Any IP address since it's web/https for public, if it was for specific ip we do "1.1.1.1/32"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"        #means any protocol
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

#7.Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.prod_allow_web.id]
  
}