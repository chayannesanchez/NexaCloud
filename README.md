# NexaCloud Betek Support Portal

Proyecto serverless para crear, consultar y gestionar tickets de soporte técnico en AWS.

## Arquitectura implementada

- **Frontend:** HTML, CSS y JavaScript vanilla desplegado como sitio estático en Amazon S3.
- **API:** Amazon API Gateway REST API.
- **Backend:** 3 funciones AWS Lambda en Python:
  - `create-ticket`: crea tickets públicos desde el formulario.
  - `get-tickets`: lista tickets, consulta detalle por ID y permite seguimiento público por número de ticket.
  - `update-ticket`: actualiza estado, asignado y notas internas.
- **Base de datos:** Amazon DynamoDB con tabla de tickets.
- **Autenticación:** Amazon Cognito User Pool para proteger el panel de soporte.
- **Monitoreo:** CloudWatch Log Groups por Lambda y alarmas básicas de errores/duración.
- **CI/CD:** GitHub Actions con Terraform usando `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`.

## Estructura principal

```text
.github/workflows/deploy.yaml
backend/
  create_ticket/app.py
  get_tickets/app.py
  update_ticket/app.py
terraform/
  backend.tf
  cloudwatch.tf
  dev.tfvars
  main.tf
  outputs.tf
  prod.tfvars
  provider.tf
  terraform.tfvars
  variables.tf
  versions.tf
  modules/
    API_gateway/
    Cognito/
    DynamoDB/
    Lambda/
    S3/
webpages/
  api-config.js
  auth-cognito.js
  form/
  index/
  login/
  support/
  track/
```

## Recursos manuales requeridos antes del primer despliegue

Terraform usa backend remoto S3. Antes del primer `terraform init`, crea manualmente:

### 1. Bucket S3 para estado

```text
nexacloud-betek-tfstate-charles-2026
```

Configuración recomendada:

```text
Region: us-east-1
Block all public access: ON
Bucket versioning: Enable
Default encryption: SSE-S3
```

### 2. Tabla DynamoDB para bloqueo del estado

```text
nexacloud-betek-tf-locks
```

Configuración:

```text
Partition key: LockID
Type: String
Billing mode: On-demand / PAY_PER_REQUEST
```

El archivo `terraform/backend.tf` ya referencia ese bucket y esa tabla.

## Variables de ambiente Terraform

El pipeline usa:

```text
terraform/dev.tfvars
```

Para producción puedes usar manualmente:

```bash
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

El archivo `terraform/terraform.tfvars` se conserva para ejecución local, pero GitHub Actions usa explícitamente `dev.tfvars`.

## Secrets requeridos en GitHub

Configura en el repositorio:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

La región del workflow está configurada en:

```text
us-east-1
```

## Despliegue automático

El workflow se ejecuta con cada `push` a `main` y también manualmente desde `workflow_dispatch`.

Pasos principales:

```text
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars
terraform apply -auto-approve tfplan
```

Al finalizar, GitHub Actions muestra:

```text
website_url
website_bucket_name
api_endpoint
dynamodb_table_name
cognito_user_pool_id
cognito_client_id
support_admin_user
```

## Usuario inicial de soporte

Configurado en `terraform/dev.tfvars`:

```hcl
admin_email         = "sanchez_ocana@hotmail.com"
admin_temp_password = "NexaCloud123!"
```

Cognito solicitará cambiar la contraseña temporal en el primer inicio de sesión.

## Destrucción de infraestructura

Desde GitHub Actions ejecuta manualmente el workflow y marca:

```text
destroy = true
```

El pipeline ejecutará:

```text
terraform plan -destroy -var-file=dev.tfvars
terraform apply -auto-approve tfplan
```

## Nota sobre S3 público

El frontend se sirve como S3 static website con política pública de lectura. Si la cuenta AWS tiene bloqueo público a nivel de cuenta, debes permitir políticas públicas para este bucket de frontend o migrar a CloudFront con Origin Access Control.
