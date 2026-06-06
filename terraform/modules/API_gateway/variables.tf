variable "api_name" {
  type        = string
  description = "Nombre del REST API Gateway."
}

variable "stage_name" {
  type        = string
  description = "Nombre del stage de despliegue."
  default     = "prod"
}

variable "lambda_tickets_create_invoke_arn" {
  type        = string
  description = "invoke_arn de la Lambda que crea tickets."
}

variable "lambda_tickets_create_function_name" {
  type        = string
  description = "Nombre de la Lambda que crea tickets."
}

variable "lambda_tickets_get_invoke_arn" {
  type        = string
  description = "invoke_arn de la Lambda que consulta tickets."
}

variable "lambda_tickets_get_function_name" {
  type        = string
  description = "Nombre de la Lambda que consulta tickets."
}

variable "lambda_tickets_update_invoke_arn" {
  type        = string
  description = "invoke_arn de la Lambda que actualiza tickets."
}

variable "lambda_tickets_update_function_name" {
  type        = string
  description = "Nombre de la Lambda que actualiza tickets."
}

variable "cognito_user_pool_arn" {
  type        = string
  description = "ARN del User Pool de Cognito usado para proteger endpoints privados."
}

variable "enable_cognito_auth" {
  type        = bool
  description = "Habilita autorización Cognito en endpoints privados."
  default     = true
}

variable "lambda_agents_invoke_arn" {
  description = "ARN de invocación de la Lambda de agentes."
  type        = string
}

variable "lambda_agents_function_name" {
  description = "Nombre de la función Lambda de agentes."
  type        = string
}
