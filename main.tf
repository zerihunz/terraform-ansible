# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
 
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

variable "subnet_prefix" {
  description = "cidr block for the subnet" 
  #default     = "10.0.66.0/24"       //If no value is provided, the default here will be used.
  #type = string
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
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  tags = {
    Name = "Prod route table"
  }
}

#4.Create a Subnet where our webserver is going to reside on
resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[0]                 //variable defined above
  #cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
    #Name = var.subnet_prefix[0].name                with the object, use it this way
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_prefix[1]                 //variable defined above
  #cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "dev-subnet"
    #Name = var.subnet_prefix[1].name
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

output "server_public_ip" {         //This will show public ip everytime we run "terraform apply"
  value = aws_eip.one.public_ip
}

#8.Assign an elastic IP to the network interface created in step 7 (Elastic IP is a public IP that's routable on the internet)
resource "aws_eip" "one" {
  vpc                       = true    // (Optional) Boolean if the EIP is in a VPC or not.
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.prod-gw]      //Can't create Elastic IP without gateway, so use depends on 
}

#9.Create ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
  ami = "ami-0279c3b3186e54acd"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"       //Availability zone should be hardcoded this way other wise aws would complain it's in a different zone by assigning a random availability zone
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF
  tags = {
    Name = "web-server"
  }              
}

output "server_private_ip" {
  value = aws_instance.web-server-instance.private_ip
}

output "server_id" {
  value = aws_instance.web-server-instance.id
}