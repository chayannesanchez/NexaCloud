# ARCHIVO MODIFICADO
# DynamoDB/variables.tf — agrega agents_table_name

variable "table_name" {
  description = "Nombre de la tabla DynamoDB de tickets."
  type        = string
}

variable "agents_table_name" {
  description = "Nombre de la tabla DynamoDB de agentes."
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue."
  type        = string
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
