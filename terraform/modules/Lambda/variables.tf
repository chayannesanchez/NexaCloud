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
  description = "Nombre de la tabla DynamoDB."
  type        = string
}

variable "table_arn" {
  description = "ARN de la tabla DynamoDB."
  type        = string
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
