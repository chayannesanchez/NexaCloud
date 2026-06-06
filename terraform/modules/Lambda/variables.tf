# ARCHIVO MODIFICADO
# Lambda/variables.tf — agrega agents_table_name y agents_table_arn opcionales

variable "function_name" {
  description = "Nombre de la función Lambda."
  type        = string
}

variable "source_dir" {
  description = "Directorio fuente de la función Lambda."
  type        = string
}

variable "handler" {
  description = "Handler Lambda."
  type        = string
}

variable "runtime" {
  description = "Runtime Lambda."
  type        = string
  default     = "python3.12"
}

variable "table_name" {
  description = "Nombre de la tabla DynamoDB de tickets."
  type        = string
}

variable "table_arn" {
  description = "ARN de la tabla DynamoDB de tickets."
  type        = string
}

variable "agents_table_name" {
  description = "Nombre de la tabla DynamoDB de agentes (opcional)."
  type        = string
  default     = ""
}

variable "agents_table_arn" {
  description = "ARN de la tabla DynamoDB de agentes (opcional)."
  type        = string
  default     = ""
}

variable "dynamodb_actions" {
  description = "Acciones DynamoDB permitidas para esta función Lambda."
  type        = list(string)
}

variable "memory_size" {
  description = "Memoria Lambda en MB."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Timeout Lambda en segundos."
  type        = number
  default     = 15
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}

variable "extra_environment_variables" {
  description = "Variables de entorno adicionales para la función Lambda."
  type        = map(string)
  default     = {}
}

variable "s3_bucket_arn" {
  description = "ARN de bucket S3 opcional al que la Lambda puede escribir/leer."
  type        = string
  default     = ""
}


variable "cognito_user_pool_arn" {
  description = "ARN del User Pool de Cognito al que la Lambda puede administrar usuarios opcionalmente."
  type        = string
  default     = ""
}

variable "cognito_actions" {
  description = "Acciones Cognito permitidas para esta función Lambda."
  type        = list(string)
  default     = []
}
