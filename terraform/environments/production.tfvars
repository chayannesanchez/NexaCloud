aws_region   = "us-east-1"
project_name = "nexacloud-betek-charles"
environment  = "prod"

lambda_runtime    = "python3.12"
create_admin_user = true

tags = {
  Environment = "production"
  Project     = "NexaCloud-Betek"
  ManagedBy   = "Terraform"
  Owner       = "NexaCloud-Team"
}
