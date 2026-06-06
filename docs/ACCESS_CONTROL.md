# Control de acceso

Este proyecto separa la aplicación en dos zonas: una zona pública para clientes y una zona administrativa para soporte.

## Zonas de la aplicación

| Zona | Archivos principales | Acceso | Propósito |
|---|---|---|---|
| Usuario / Cliente | `webpages/index/index.html`, `webpages/form/form.html`, `webpages/track/track.html` | Público | Crear tickets y hacer seguimiento. |
| Administración / Soporte | `webpages/login/login.html`, `webpages/support/support.html` | Autenticado con Cognito | Gestionar tickets, agentes y estados. |

## Endpoints públicos

Estos endpoints no requieren autenticación:

```text
POST /tickets/create
GET  /tickets/track/{id}
PUT  /tickets/{id}/reply
```

Uso esperado:

- El cliente crea un ticket.
- El cliente consulta únicamente el estado de su ticket.
- El cliente responde desde la pantalla de seguimiento.

La vista pública no expone notas internas ni listado completo de tickets.

## Endpoints administrativos

Estos endpoints requieren token válido de Amazon Cognito enviado en el header `Authorization`:

```text
GET    /tickets/list
GET    /tickets/{id}
PUT    /tickets/{id}/update
GET    /agents
POST   /agents
DELETE /agents/{id}
```

La protección se maneja en dos capas:

1. **API Gateway Cognito Authorizer:** bloquea solicitudes sin token válido.
2. **Lambda defensiva:** valida que existan claims de Cognito antes de procesar operaciones administrativas.

## Roles administrativos

El sistema maneja estos roles en la tabla de agentes:

| Rol | Permisos principales |
|---|---|
| `agent` | Ver tickets, atender casos y responder al cliente. |
| `senior_agent` | Igual que agente; reservado para reglas futuras. |
| `supervisor` | Gestionar tickets y administrar soportes técnicos. |
| `admin` | Usuario inicial del sistema, con permisos administrativos completos. |

## Usuario administrador inicial

Terraform crea un usuario inicial en Cognito si `create_admin_user = true`.

Además, se crea un registro inicial en la tabla DynamoDB de agentes con rol `admin`:

```text
agentId: ADM-{ENVIRONMENT}
role: admin
email: var.admin_email
```

Este usuario permite iniciar sesión y registrar nuevos soportes técnicos desde el panel.

## Reglas aplicadas en frontend

En `webpages/support/support.html` se aplicaron estas reglas:

- Si no hay sesión válida, se redirige a `webpages/login/login.html`.
- Se muestra el usuario autenticado y su rol.
- El formulario para registrar soportes solo se muestra a `admin` o `supervisor`.
- Los botones para eliminar soportes solo aparecen para `admin` o `supervisor`.

## Reglas aplicadas en backend

### `backend/get_tickets/app.py`

- `GET /tickets/track/{id}` sigue siendo público.
- `GET /tickets/list` requiere sesión Cognito.
- `GET /tickets/{id}` requiere sesión Cognito.

### `backend/update_ticket/app.py`

- `PUT /tickets/{id}/reply` sigue siendo público para el cliente.
- `PUT /tickets/{id}/update` requiere sesión Cognito.

### `backend/agents/app.py`

- `GET /agents` requiere sesión Cognito.
- `POST /agents` requiere rol `admin` o `supervisor`.
- `DELETE /agents/{id}` requiere rol `admin` o `supervisor`.

## Recomendación para producción

Para una versión productiva más estricta se recomienda complementar esta solución con:

- Grupos de Cognito (`admin`, `supervisor`, `agent`).
- Claims personalizados o mapeo de grupos en el token JWT.
- Auditoría de acciones administrativas.
- Políticas IAM más segmentadas por Lambda.
- URLs firmadas para evidencias sensibles en S3.
