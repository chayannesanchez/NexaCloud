# ARCHIVO MODIFICADO
# terraform/main.tf
# Agrega: tabla agents, Lambda agents, endpoints API Gateway para agentes.
# Conecta AGENTS_TABLE a update_ticket para sincronización de contadores.

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "terraform_data" "validate_admin_credentials" {
  count = var.create_admin_user ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(trimspace(var.admin_email)) > 0
      error_message = "admin_email está vacío. Configura TF_VAR_admin_email localmente o el secret TF_ADMIN_EMAIL en GitHub Actions."
    }

    precondition {
      condition     = length(trimspace(var.admin_temp_password)) >= 8
      error_message = "admin_temp_password está vacío o es muy corto. Configura TF_VAR_admin_temp_password localmente o el secret TF_ADMIN_TEMP_PASSWORD en GitHub Actions."
    }
  }
}

module "dynamodb" {
  source            = "./modules/DynamoDB"
  table_name        = "${local.name_prefix}-tickets"
  agents_table_name = "${local.name_prefix}-agents"
  environment       = var.environment
  tags              = var.tags
}


resource "random_id" "evidence_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "evidence" {
  bucket = lower("${local.name_prefix}-evidence-${random_id.evidence_bucket_suffix.hex}")
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "evidence" {
  bucket = aws_s3_bucket.evidence.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "evidence_public_read" {
  bucket = aws_s3_bucket.evidence.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadEvidenceObjects"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.evidence.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.evidence]
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

# Usuario administrativo inicial para el panel.
# Permite que el primer usuario creado en Cognito también exista como agente administrador.
resource "aws_dynamodb_table_item" "admin_agent" {
  count      = var.create_admin_user ? 1 : 0
  table_name = module.dynamodb.agents_table_name
  hash_key   = "agentId"

  item = jsonencode({
    agentId         = { S = "ADM-${upper(var.environment)}" }
    name            = { S = "Administrador" }
    email           = { S = lower(var.admin_email) }
    role            = { S = "admin" }
    active          = { BOOL = true }
    loginEnabled    = { BOOL = true }
    assignedTickets = { N = "0" }
    createdAt       = { S = "seeded-by-terraform" }
    managedBy       = { S = "terraform" }
  })
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
  s3_bucket_arn   = aws_s3_bucket.evidence.arn
  extra_environment_variables = {
    EVIDENCE_BUCKET          = aws_s3_bucket.evidence.id
    EVIDENCE_PUBLIC_BASE_URL = "https://${aws_s3_bucket.evidence.bucket_regional_domain_name}"
  }
  tags             = var.tags
}

module "lambda_get_tickets" {
  source            = "./modules/Lambda"
  function_name     = "${local.name_prefix}-get-tickets"
  source_dir        = "${path.root}/../backend/get_tickets"
  handler           = "app.handler"
  runtime           = var.lambda_runtime
  table_name        = module.dynamodb.table_name
  table_arn         = module.dynamodb.table_arn
  agents_table_name = module.dynamodb.agents_table_name
  agents_table_arn  = module.dynamodb.agents_table_arn
  dynamodb_actions  = ["dynamodb:GetItem", "dynamodb:Scan"]
  tags              = var.tags
}

module "lambda_update_ticket" {
  source            = "./modules/Lambda"
  function_name     = "${local.name_prefix}-update-ticket"
  source_dir        = "${path.root}/../backend/update_ticket"
  handler           = "app.handler"
  runtime           = var.lambda_runtime
  table_name        = module.dynamodb.table_name
  table_arn         = module.dynamodb.table_arn
  agents_table_name = module.dynamodb.agents_table_name
  agents_table_arn  = module.dynamodb.agents_table_arn
  dynamodb_actions  = ["dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:Scan"]
  tags              = var.tags
}

module "lambda_agents" {
  source                 = "./modules/Lambda"
  function_name          = "${local.name_prefix}-agents"
  source_dir             = "${path.root}/../backend/agents"
  handler                = "app.handler"
  runtime                = var.lambda_runtime
  table_name             = module.dynamodb.agents_table_name
  table_arn              = module.dynamodb.agents_table_arn
  agents_table_name      = module.dynamodb.agents_table_name
  agents_table_arn       = module.dynamodb.agents_table_arn
  dynamodb_actions       = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Scan", "dynamodb:UpdateItem", "dynamodb:DeleteItem"]
  cognito_user_pool_arn  = module.cognito.user_pool_arn
  cognito_actions        = ["cognito-idp:AdminCreateUser", "cognito-idp:AdminSetUserPassword", "cognito-idp:AdminDeleteUser"]
  extra_environment_variables = {
    COGNITO_USER_POOL_ID = module.cognito.user_pool_id
    ADMIN_EMAIL          = var.admin_email
  }
  tags = var.tags
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

  lambda_agents_invoke_arn    = module.lambda_agents.invoke_arn
  lambda_agents_function_name = module.lambda_agents.function_name

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
