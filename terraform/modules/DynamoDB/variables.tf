variable "table_name" {
  description = "Nombre de la tabla DynamoDB para tickets."
  type        = string
}

variable "environment" {
  description = "Ambiente del proyecto."
  type        = string
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
