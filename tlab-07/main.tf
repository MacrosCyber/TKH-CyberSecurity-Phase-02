provider "aws" {  
  region = "us-east-1"  
}  
  
resource "aws_security_group" "sabotaged_sg" {  
  name        = "tlab7-exposed-sg"  
  description = "A secured security group"  
  
  ingress {  
    description = "Allow restricted SSH access from my IP" # TFSEC REQUIRES THIS
    from_port   = 22  
    to_port     = 22  
    protocol    = "tcp"  
    cidr_blocks = ["98.15.56.216/32"] 
  }  
}
