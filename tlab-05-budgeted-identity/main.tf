provider "aws" {  
  region = "us-east-1"
}

# The Guardrail
resource "aws_budgets_budget" "tlab_budget" {  
  name              = "TLAB-Strict-Budget"  
  budget_type       = "COST"  
  limit_amount      = "10"  
  limit_unit        = "USD"  
  time_unit         = "MONTHLY"  

  notification {    
    comparison_operator        = "GREATER_THAN"    
    notification_type          = "ACTUAL"    
    threshold                  = 80    
    threshold_type             = "PERCENTAGE"    
    subscriber_email_addresses = ["mcruz21597@gmail.com"]  
  }
}

# Generate a random string to ensure the S3 bucket name is globally unique
resource "random_id" "id" {
  byte_length = 4
}

# Step 3: The Secure S3 Vault
resource "aws_s3_bucket" "titan_vault" {
  # Notice the dynamic interpolation pulling in the random hex and using your initials (mc)
  bucket = "titan-fintech-vault-mc-${random_id.id.hex}"
}

# Step 4: The IAM Role (The "Identity" for our EC2 server)
resource "aws_iam_role" "titan_ec2_role" {
  name = "Titan-EC2-Vault-Role"

  # The Trust Policy: This strictly dictates WHO or WHAT is allowed to assume this role.
  # We are explicitly stating that only an EC2 instance can put on this "hat".
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Step 4: The Surgical Permissions Policy
resource "aws_iam_role_policy" "titan_vault_policy" {
  name = "titan-s3-put-only"
  role = aws_iam_role.titan_ec2_role.id

  # The Permission Policy: This dictates WHAT the entity wearing the "hat" is allowed to do.
  # We are restricting it strictly to uploading objects, and ONLY to the exact ARN of our new bucket.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Resource = "${aws_s3_bucket.titan_vault.arn}/*"
      }
    ]
  })
}

# Step 5 - Part 1: The Instance Profile (The Bridge)
resource "aws_iam_instance_profile" "titan_ec2_profile" {
  name = "titan-vault-ec2-profile"
  role = aws_iam_role.titan_ec2_role.name
}

# Step 5 - Part 2: Dynamic AMI Data Source (The Operating System Blueprint)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID (creators of Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Step 5 - Part 3: The Compute Resource (The EC2 Server)
resource "aws_instance" "titan_app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.titan_ec2_profile.name

  tags = {
    Name = "Titan-FinTech-App-Server"
  }
}