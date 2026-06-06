# GitHub Actions

El repositorio queda preparado para ejecutar validaciones y despliegue automático con GitHub Actions.

## Workflows incluidos

| Workflow | Archivo | Propósito |
|---|---|---|
| CI | `.github/workflows/ci.yml` | Valida sintaxis Python y estructura Terraform en pull request o push. |
| Deploy NexaCloud Betek AWS Serverless | `.github/workflows/terraform-deploy.yml` | Despliega o destruye infraestructura con Terraform. |

## Secrets requeridos

Para desplegar desde GitHub Actions configura estos secrets en el repositorio:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
TF_ADMIN_EMAIL
TF_ADMIN_TEMP_PASSWORD
```

El usuario `TF_ADMIN_EMAIL` será el primer usuario administrativo del panel.

La contraseña `TF_ADMIN_TEMP_PASSWORD` debe cumplir la política de Cognito:

- Mínimo 8 caracteres.
- Al menos una minúscula.
- Al menos una mayúscula.
- Al menos un número.
- Al menos un símbolo.

Ejemplo válido:

```text
Temporal123!
```

No uses ese ejemplo como contraseña real de producción.

## Flujo de despliegue

El despliegue automático ocurre cuando se hace `push` a la rama `main`.

Pasos principales:

1. Checkout del repositorio.
2. Validación de Secrets requeridos.
3. Configuración de credenciales AWS.
4. Creación o reutilización automática del backend remoto de Terraform en S3 y DynamoDB.
5. Instalación de Terraform.
6. `terraform init` con backend dinámico.
7. `terraform fmt -recursive -check`.
8. `terraform validate`.
9. `terraform plan -var-file=environments/development.tfvars`.
10. `terraform apply`.
11. Muestra outputs del despliegue, incluyendo `website_url`.

## Despliegue manual

Desde la pestaña **Actions** de GitHub puedes ejecutar manualmente el workflow `Deploy NexaCloud Betek AWS Serverless` usando `workflow_dispatch`.

Opciones:

```text
destroy = false  # despliega o actualiza infraestructura
destroy = true   # destruye infraestructura
```

## Recomendación de seguridad

Para producción se recomienda reemplazar llaves de acceso por OIDC con un rol IAM asumido por GitHub Actions.
