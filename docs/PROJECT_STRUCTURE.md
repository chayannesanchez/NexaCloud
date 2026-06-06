# Estructura del proyecto

```text
.
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml
├── backend/
│   ├── agents/
│   │   └── app.py
│   ├── create_ticket/
│   │   └── app.py
│   ├── get_tickets/
│   │   └── app.py
│   └── update_ticket/
│       └── app.py
├── doc/
│   ├── proyecto-betek.drawio
│   ├── tree.txt
│   └── Proyecto 2 - Despliegue de una Aplicación Web Utilizando CI-CD.pdf
├── docs/
│   ├── API.md
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── LOCAL_DEVELOPMENT.md
│   ├── OPERATIONS.md
│   ├── PROJECT_STRUCTURE.md
│   └── USER_GUIDE.md
├── terraform/
│   ├── modules/
│   │   ├── API_gateway/
│   │   ├── Cognito/
│   │   ├── DynamoDB/
│   │   ├── Lambda/
│   │   └── S3/
│   ├── environments/
│   │   ├── development.tfvars
│   │   └── production.tfvars
│   ├── backend.tf
│   ├── cloudwatch.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── variables.tf
│   └── versions.tf
├── webpages/
│   ├── form/
│   ├── index/
│   ├── login/
│   ├── support/
│   ├── track/
│   ├── api-config.js
│   ├── auth-cognito.js
│   ├── index.html
│   ├── style.css
│   └── theme.js
├── .gitignore
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── SECURITY.md
└── SUPPORT.md
```

## Carpetas principales

### `backend/`

Contiene las funciones Lambda en Python.

| Carpeta | Función |
|---|---|
| `create_ticket` | Crea tickets y sube evidencia a S3. |
| `get_tickets` | Lista tickets, obtiene detalle y seguimiento público. |
| `update_ticket` | Actualiza estado, asignación, notas y respuestas. |
| `agents` | Gestiona agentes y usuarios Cognito. |

### `webpages/`

Contiene el frontend estático.

| Carpeta/archivo | Función |
|---|---|
| `index/` | Página principal. |
| `form/` | Formulario público de tickets. |
| `login/` | Inicio de sesión con Cognito. |
| `support/` | Panel de soporte. |
| `track/` | Seguimiento público de tickets. |
| `api-config.js` | Configuración del API y Cognito. |
| `auth-cognito.js` | Lógica de autenticación. |

### `terraform/`

Contiene IaC del proyecto.

| Archivo/carpeta | Función |
|---|---|
| `main.tf` | Orquesta módulos y recursos principales. |
| `backend.tf` | Backend remoto de Terraform. |
| `variables.tf` | Variables del proyecto. |
| `outputs.tf` | Salidas importantes. |
| `cloudwatch.tf` | Alarmas de monitoreo. |
| `modules/` | Módulos reutilizables de AWS. |

### `docs/`

Documentación técnica para GitHub y mantenimiento del proyecto.


## Observaciones

- La carpeta `docs/assets/` contiene la imagen de arquitectura en PNG y el archivo fuente editable en Draw.io.


## Documento de descripción del proyecto

- `docs/PROJECT_DESCRIPTION.md`: resumen en Markdown del enunciado base.
- `docs/assets/project-description.pdf`: archivo PDF original de la descripción del proyecto.


## Archivos agregados en esta versión

- `docs/ACCESS_CONTROL.md`: documentación de separación público/administrativo y roles.
- `docs/GITHUB_ACTIONS.md`: guía para ejecutar CI/CD en GitHub Actions.
- `.github/workflows/ci.yml`: validación automática de Python y Terraform.


## Configuración por ambiente

La configuración de Terraform está separada en archivos profesionales por ambiente:

- `terraform/environments/development.tfvars`
- `terraform/environments/production.tfvars`

Los secretos no se guardan en estos archivos. Se gestionan con variables de entorno o GitHub Secrets.
