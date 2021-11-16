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



#resource "<provider>_<resource_type>" "name" {
#    config options.....connection 
#    key = "value"  
#    key2 = "another value"
#} 