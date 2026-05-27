terraform {
  backend "s3" {
    bucket         = "nexacloud-betek-tfstate-charles-2026"
    key            = "nexacloud-betek/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "nexacloud-betek-tf-locks"
  }
}
