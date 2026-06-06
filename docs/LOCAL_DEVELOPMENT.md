# Desarrollo local

## Frontend

El frontend está en `webpages/` y usa HTML, CSS y JavaScript vanilla.

Para revisar las páginas localmente puedes usar un servidor simple:

```bash
cd webpages
python -m http.server 8080
```

Luego abre:

```text
http://localhost:8080
```

## Configuración de API local

El archivo `webpages/api-config.js` viene con placeholders. En AWS, Terraform reemplaza este archivo por uno generado desde `terraform/modules/S3/api-config.js.tftpl`.

Para pruebas locales, puedes editar temporalmente:

```js
const API_CONFIG = {
  BASE_URL: 'https://TU_API.execute-api.us-east-1.amazonaws.com/prod'
}
```

No subas URLs internas o credenciales sensibles si el repositorio será público.

## Backend Lambda

Cada Lambda está en una carpeta independiente:

```text
backend/create_ticket/app.py
backend/get_tickets/app.py
backend/update_ticket/app.py
backend/agents/app.py
```

Las Lambdas esperan variables de entorno como:

```text
TABLE_NAME
AGENTS_TABLE
EVIDENCE_BUCKET
EVIDENCE_PUBLIC_BASE_URL
COGNITO_USER_POOL_ID
```

AWS Lambda ya incluye `boto3`, por eso no se requiere `requirements.txt` para el despliegue actual.

## Validación básica de Python

Desde la raíz:

```bash
python -m py_compile backend/create_ticket/app.py
python -m py_compile backend/get_tickets/app.py
python -m py_compile backend/update_ticket/app.py
python -m py_compile backend/agents/app.py
```

## Terraform

Para validar infraestructura sin aplicar cambios:

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=environments/development.tfvars
```

## Convención de ramas sugerida

```text
main                 Rama estable
develop              Integración de cambios
feature/<nombre>     Nuevas funcionalidades
fix/<nombre>         Correcciones
```

## Checklist antes de subir cambios

- [ ] No hay archivos con secretos o credenciales versionados.
- [ ] No hay credenciales AWS en el código.
- [ ] No hay carpetas `__pycache__`.
- [ ] Terraform está formateado.
- [ ] README y documentación se actualizaron.
- [ ] El frontend apunta al API correcto después del despliegue.
