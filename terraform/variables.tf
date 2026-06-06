variable "aws_region" {
  description = "Región AWS donde se desplegará el proyecto."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto para nombrar recursos."
  type        = string
  default     = "nexacloud-betek-charles"
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
  description = "Correo/usuario inicial para entrar al panel de soporte. Se recomienda configurarlo con TF_VAR_admin_email o GitHub Secrets."
  type        = string
  default     = ""

  validation {
    condition     = var.admin_email == "" || can(regex("^[^@ ]+@[^@ ]+[.][^@ ]+$", var.admin_email))
    error_message = "admin_email debe tener formato de correo válido."
  }
}

variable "admin_temp_password" {
  description = "Contraseña temporal del usuario inicial. Se recomienda configurarla con TF_VAR_admin_temp_password o GitHub Secrets."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = var.admin_temp_password == "" || length(var.admin_temp_password) >= 8
    error_message = "admin_temp_password debe tener mínimo 8 caracteres."
  }
}

variable "lambda_runtime" {
  description = "Runtime Python para las funciones Lambda."
  type        = string
  default     = "python3.12"
}
