# Guía de despliegue

## Requisitos previos

- Terraform `>= 1.5`.
- AWS CLI configurado o credenciales mediante variables de entorno.
- Permisos en AWS para crear y administrar:
  - S3
  - DynamoDB
  - Lambda
  - API Gateway
  - Cognito
  - IAM
  - CloudWatch
- Para GitHub Actions, el backend remoto se crea automáticamente. Para despliegue local, puedes usar un backend S3 propio.

## Backend remoto de Terraform

El archivo `terraform/backend.tf` declara un backend S3 sin valores quemados en el código.

En GitHub Actions, el workflow crea o reutiliza automáticamente:

```text
S3 bucket de estado: nexacloud-betek-dev-tfstate-<AWS_ACCOUNT_ID>
DynamoDB lock table: nexacloud-betek-dev-tf-locks
Partition key: LockID tipo String
```

Para despliegue local, puedes usar tus propios nombres de bucket y tabla al ejecutar `terraform init`.

Configuración recomendada para el bucket de estado:

- Versioning habilitado.
- Bloqueo de acceso público activado.
- Cifrado SSE-S3 o SSE-KMS.

## Despliegue local

Desde la raíz del proyecto:

```bash
cd terraform
export TF_VAR_admin_email="tu-correo@dominio.com"
export TF_VAR_admin_temp_password='Temporal123!'
```

Inicializa Terraform con tu backend remoto:

```bash
terraform init \
  -backend-config="bucket=TU_BUCKET_TFSTATE" \
  -backend-config="key=nexacloud-betek/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=TU_TABLA_TF_LOCKS" \
  -backend-config="encrypt=true"
```

Luego ejecuta:

```bash
terraform fmt -recursive
terraform validate
terraform plan -var-file=environments/development.tfvars
terraform apply -var-file=environments/development.tfvars
```

## Outputs importantes

Después del despliegue:

```bash
terraform output
```

Outputs principales:

| Output | Uso |
|---|---|
| `website_url` | URL pública del frontend. |
| `website_bucket_name` | Bucket S3 del sitio web. |
| `api_endpoint` | URL base del API Gateway. |
| `dynamodb_table_name` | Tabla de tickets. |
| `cognito_user_pool_id` | User Pool de Cognito. |
| `cognito_client_id` | App Client usado por el frontend. |
| `evidence_bucket_name` | Bucket de imágenes de evidencia. |

## Despliegue con GitHub Actions

El workflow se encuentra en:

```text
.github/workflows/terraform-deploy.yml
```

### Secrets requeridos

Configura en GitHub: `Settings` → `Secrets and variables` → `Actions`.

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
TF_ADMIN_EMAIL
TF_ADMIN_TEMP_PASSWORD
```

### Ejecución

- En cada `push` a `main`, el workflow ejecuta plan y apply.
- También puede ejecutarse manualmente desde `Actions`.
- Para destruir infraestructura, ejecutar manualmente y seleccionar `destroy = true`.

## Variables Terraform

Las variables están en `terraform/variables.tf` y la configuración por ambiente está en `terraform/environments/`.

```text
terraform/environments/development.tfvars
terraform/environments/production.tfvars
```

| Variable | Descripción |
|---|---|
| `aws_region` | Región AWS. |
| `project_name` | Prefijo de recursos. |
| `environment` | Ambiente, por ejemplo `dev` o `prod`. |
| `tags` | Etiquetas comunes. |
| `create_admin_user` | Crea usuario inicial de soporte. |
| `admin_email` | Correo del usuario inicial. |
| `admin_temp_password` | Contraseña temporal sensible. |
| `lambda_runtime` | Runtime de Python para Lambda. |

## Destrucción local

```bash
cd terraform
terraform plan -destroy -var-file=environments/development.tfvars
terraform destroy -var-file=environments/development.tfvars
```

## Recomendaciones

- No subir contraseñas, credenciales AWS ni valores privados.
- Usar una contraseña temporal fuerte y cambiarla después del primer ingreso.
- Verificar costos de AWS antes de dejar recursos desplegados.
- Para producción, usar CloudFront en lugar de S3 website público si se requiere HTTPS con dominio propio.


## GitHub Actions

El repositorio incluye workflows para CI y despliegue:

- `.github/workflows/ci.yml` valida sintaxis Python y Terraform.
- `.github/workflows/terraform-deploy.yml` ejecuta plan/apply o destroy.

Secrets requeridos:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
TF_ADMIN_EMAIL
TF_ADMIN_TEMP_PASSWORD
```

Consulta [`GITHUB_ACTIONS.md`](GITHUB_ACTIONS.md).


## Mantener nombre anterior con código nuevo

Esta versión mantiene el código nuevo, pero conserva el nombre base anterior de la infraestructura:

```hcl
project_name = "nexacloud-betek-charles"
environment  = "dev"
```

Con esto Terraform seguirá usando recursos con prefijo `nexacloud-betek-charles-dev-*` y no intentará migrar al prefijo `nexacloud-betek-dev-*`.

El workflow visible en GitHub Actions conserva el nombre anterior: **Deploy NexaCloud Betek AWS Serverless**.
