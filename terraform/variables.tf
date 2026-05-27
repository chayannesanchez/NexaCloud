variable "aws_region" {
  description = "Región AWS donde se desplegará el proyecto."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto para nombrar recursos."
  type        = string
  default     = "nexacloud-betek"
}

variable "environment" {
  description = "Ambiente de despliegue."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags comunes para los recursos."
  type        = map(string)
  default = {
    env     = "dev"
    owner   = "NexaCloud Team"
    project = "Betek"
  }
}

variable "create_admin_user" {
  description = "Crea un usuario inicial de soporte en Cognito para la prueba."
  type        = bool
  default     = true
}

variable "admin_email" {
  description = "Correo/usuario inicial para entrar al panel de soporte. Cambiar para pruebas reales."
  type        = string
  default     = "support@example.com"
}

variable "admin_temp_password" {
  description = "Contraseña temporal del usuario inicial. Cognito pedirá definir una nueva en el primer login."
  type        = string
  sensitive   = true
  default     = "NexaCloud123!"
}

variable "lambda_runtime" {
  description = "Runtime Python para las funciones Lambda."
  type        = string
  default     = "python3.12"
}
