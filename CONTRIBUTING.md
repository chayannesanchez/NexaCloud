# Contribuir al proyecto

Gracias por contribuir a NexaCloud Betek Support Portal.

## Flujo sugerido

1. Crear una rama desde `main`.
2. Hacer cambios pequeños y claros.
3. Validar frontend, backend y Terraform.
4. Actualizar documentación si cambia una funcionalidad.
5. Crear Pull Request hacia `main`.

## Convención de commits

Formato sugerido:

```text
tipo: descripción corta
```

Ejemplos:

```text
feat: agregar seguimiento público de tickets
fix: corregir validación de prioridad
docs: actualizar documentación de despliegue
infra: ajustar permisos de Lambda
```

## Validaciones antes del Pull Request

```bash
python -m py_compile backend/create_ticket/app.py
python -m py_compile backend/get_tickets/app.py
python -m py_compile backend/update_ticket/app.py
python -m py_compile backend/agents/app.py

cd terraform
terraform fmt -recursive
terraform validate
```

## Reglas

- No subir credenciales.
- No subir contraseñas, credenciales AWS ni archivos locales con datos privados.
- No subir `__pycache__` ni archivos generados.
- Mantener documentación actualizada.
- Explicar los cambios en el Pull Request.
