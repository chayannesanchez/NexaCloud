output "website_url" {
  value       = module.s3.website_url
  description = "URL pública del sitio web en S3."
}

output "website_bucket_name" {
  value       = module.s3.bucket_name
  description = "Nombre del bucket S3 que aloja el frontend."
}

output "api_endpoint" {
  value       = module.api_gateway.api_endpoint
  description = "URL base del API Gateway."
}

output "dynamodb_table_name" {
  value       = module.dynamodb.table_name
  description = "Nombre de la tabla DynamoDB usada por las Lambdas."
}

output "cognito_user_pool_id" {
  value       = module.cognito.user_pool_id
  description = "ID del User Pool de Cognito."
}

output "cognito_client_id" {
  value       = module.cognito.client_id
  description = "ID del App Client de Cognito."
}

output "lambda_create_ticket_name" {
  value       = module.lambda_create_ticket.function_name
  description = "Nombre de la Lambda que crea tickets."
}

output "lambda_get_tickets_name" {
  value       = module.lambda_get_tickets.function_name
  description = "Nombre de la Lambda que consulta tickets."
}

output "lambda_update_ticket_name" {
  value       = module.lambda_update_ticket.function_name
  description = "Nombre de la Lambda que actualiza tickets."
}

output "support_admin_user" {
  value       = var.create_admin_user ? var.admin_email : "No se creó usuario inicial"
  description = "Usuario inicial del panel de soporte."
}

output "evidence_bucket_name" {
  value       = aws_s3_bucket.evidence.id
  description = "Bucket S3 donde se almacenan las imágenes de evidencia de los tickets."
}
