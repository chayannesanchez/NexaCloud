variable "user_pool_name" {
  description = "Nombre del User Pool de Cognito."
  type        = string
}

variable "app_client_name" {
  description = "Nombre del App Client de Cognito."
  type        = string
}

variable "create_admin_user" {
  description = "Crear usuario inicial de soporte."
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Correo del usuario inicial de soporte."
  type        = string
  default     = ""
}

variable "admin_temp_password" {
  description = "Contraseña temporal del usuario inicial."
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}
