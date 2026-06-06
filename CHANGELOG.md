# Changelog

Todos los cambios importantes del proyecto se documentan en este archivo.

## [1.0.0] - 2026-06-04

### Agregado

- Documentación completa para GitHub.
- README principal actualizado.
- Guía de arquitectura.
- Documentación de API.
- Guía de despliegue local y GitHub Actions.
- Guía de desarrollo local.
- Guía de operación y troubleshooting.
- Guía de usuario.
- Archivo `.gitignore`.
- Workflow opcional de Terraform Deploy.
- Archivos de ambiente profesionales en `terraform/environments/` sin datos sensibles.

### Limpieza

- Eliminados archivos `__pycache__` y `.pyc` del paquete listo para GitHub.
- Evitado incluir archivos con datos sensibles o credenciales.
## 2026-06-06 - Control de acceso y GitHub Actions

### Agregado

- Separación documentada entre zona pública y zona administrativa.
- `docs/ACCESS_CONTROL.md`.
- `docs/GITHUB_ACTIONS.md`.
- Workflow `.github/workflows/ci.yml` para validación de Python y Terraform.
- Usuario administrador inicial en tabla de agentes mediante Terraform.

### Cambiado

- Protección Cognito Authorizer para endpoints `/agents`.
- Validación defensiva de sesión en Lambdas administrativas.
- Panel de soporte oculta gestión de agentes para usuarios sin rol `admin` o `supervisor`.
- Workflow de despliegue agrega validación Python y concurrencia.

### Seguridad

- La contraseña temporal administrativa queda sin valor real por defecto; debe configurarse por variables de entorno o GitHub Secrets.

