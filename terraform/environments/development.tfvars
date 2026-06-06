aws_region   = "us-east-1"
project_name = "nexacloud-betek-charles"
environment  = "dev"

lambda_runtime    = "python3.12"
create_admin_user = true

tags = {
  Environment = "development"
  Project     = "NexaCloud-Betek"
  ManagedBy   = "Terraform"
  Owner       = "NexaCloud-Team"
}
