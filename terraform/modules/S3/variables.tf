variable "project_name" {
  description = "Nombre base del proyecto."
  type        = string
}

variable "environment" {
  description = "Ambiente del proyecto."
  type        = string
}

variable "website_source_dir" {
  description = "Directorio con los archivos estáticos del frontend."
  type        = string
}

variable "api_base_url" {
  description = "URL base del API Gateway."
  type        = string
}

variable "cognito_region" {
  description = "Región de Cognito."
  type        = string
}

variable "cognito_user_pool_id" {
  description = "ID del User Pool de Cognito."
  type        = string
}

variable "cognito_client_id" {
  description = "ID del App Client de Cognito."
  type        = string
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
