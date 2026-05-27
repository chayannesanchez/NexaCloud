aws_region   = "us-east-1"
project_name = "nexacloud-betek-charles"
environment  = "dev"

tags = {
  env     = "dev"
  owner   = "Charles"
  project = "Betek"
}

create_admin_user   = true
admin_email         = "sanchez_ocana@hotmail.com"
admin_temp_password = "NexaCloud123!"
lambda_runtime      = "python3.12"
