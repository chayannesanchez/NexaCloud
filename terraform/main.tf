locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "dynamodb" {
  source      = "./modules/DynamoDB"
  table_name  = "${local.name_prefix}-tickets"
  environment = var.environment
  tags        = var.tags
}

module "cognito" {
  source              = "./modules/Cognito"
  user_pool_name      = "${local.name_prefix}-users"
  app_client_name     = "${local.name_prefix}-web-client"
  create_admin_user   = var.create_admin_user
  admin_email         = var.admin_email
  admin_temp_password = var.admin_temp_password
  tags                = var.tags
}

module "lambda_create_ticket" {
  source           = "./modules/Lambda"
  function_name    = "${local.name_prefix}-create-ticket"
  source_dir       = "${path.root}/../backend/create_ticket"
  handler          = "app.handler"
  runtime          = var.lambda_runtime
  table_name       = module.dynamodb.table_name
  table_arn        = module.dynamodb.table_arn
  dynamodb_actions = ["dynamodb:PutItem"]
  tags             = var.tags
}

module "lambda_get_tickets" {
  source        = "./modules/Lambda"
  function_name = "${local.name_prefix}-get-tickets"
  source_dir    = "${path.root}/../backend/get_tickets"
  handler       = "app.handler"
  runtime       = var.lambda_runtime
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
  dynamodb_actions = [
    "dynamodb:GetItem",
    "dynamodb:Scan"
  ]
  tags = var.tags
}

module "lambda_update_ticket" {
  source           = "./modules/Lambda"
  function_name    = "${local.name_prefix}-update-ticket"
  source_dir       = "${path.root}/../backend/update_ticket"
  handler          = "app.handler"
  runtime          = var.lambda_runtime
  table_name       = module.dynamodb.table_name
  table_arn        = module.dynamodb.table_arn
  dynamodb_actions = ["dynamodb:UpdateItem"]
  tags             = var.tags
}

module "api_gateway" {
  source     = "./modules/API_gateway"
  api_name   = "${local.name_prefix}-api"
  stage_name = "prod"

  lambda_tickets_create_invoke_arn    = module.lambda_create_ticket.invoke_arn
  lambda_tickets_create_function_name = module.lambda_create_ticket.function_name

  lambda_tickets_get_invoke_arn    = module.lambda_get_tickets.invoke_arn
  lambda_tickets_get_function_name = module.lambda_get_tickets.function_name

  lambda_tickets_update_invoke_arn    = module.lambda_update_ticket.invoke_arn
  lambda_tickets_update_function_name = module.lambda_update_ticket.function_name

  cognito_user_pool_arn = module.cognito.user_pool_arn
  enable_cognito_auth   = true
}

module "s3" {
  source               = "./modules/S3"
  project_name         = var.project_name
  environment          = var.environment
  website_source_dir   = "${path.root}/../webpages"
  api_base_url         = module.api_gateway.api_endpoint
  cognito_region       = var.aws_region
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.client_id
  tags                 = var.tags
}
