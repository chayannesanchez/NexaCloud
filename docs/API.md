# Documentación de API

## Base URL

La URL base se obtiene del output de Terraform:

```bash
terraform output api_endpoint
```

Formato esperado:

```text
https://{api-id}.execute-api.{region}.amazonaws.com/prod
```

## Autenticación

Los endpoints públicos no requieren token. Los endpoints del panel de soporte usan token de Cognito en el header:

```http
Authorization: <ID_TOKEN_COGNITO>
Content-Type: application/json
```

Los endpoints administrativos están protegidos con Cognito Authorizer en API Gateway y validación defensiva en Lambda.

Consulta también [`ACCESS_CONTROL.md`](ACCESS_CONTROL.md).

## Respuesta estándar

La mayoría de respuestas usan este formato:

```json
{
  "success": true,
  "message": "Operación completada"
}
```

En errores:

```json
{
  "success": false,
  "message": "Descripción del error"
}
```

---

# Tickets

## Crear ticket

```http
POST /tickets/create
```

Acceso: público.

### Body

```json
{
  "fullname": "Juan Pérez",
  "email": "juan@example.com",
  "phone": "3001234567",
  "category": "technical",
  "priority": "medium",
  "subject": "No puedo ingresar al sistema",
  "description": "Al intentar iniciar sesión aparece un error.",
  "evidenceImage": {
    "name": "captura.png",
    "type": "image/png",
    "data": "data:image/png;base64,iVBORw0KGgo..."
  }
}
```

### Campos válidos

| Campo | Tipo | Requerido | Descripción |
|---|---:|---:|---|
| `fullname` | string | Sí | Nombre completo del solicitante. |
| `email` | string | Sí | Correo válido del solicitante. |
| `phone` | string | No | Teléfono de contacto. |
| `category` | string | Sí | `technical`, `billing`, `account`, `general`. |
| `priority` | string | Sí | `low`, `medium`, `high`. |
| `subject` | string | Sí | Asunto del caso. |
| `description` | string | Sí | Descripción del problema. |
| `evidenceImage` | object | No | Imagen en base64, máximo 2 MB. |

### Respuesta 201

```json
{
  "success": true,
  "message": "Ticket creado correctamente.",
  "ticketId": "TKT-20260604-A1B2C3D4"
}
```

## Listar tickets

```http
GET /tickets/list
```

Acceso: soporte autenticado.

### Query params opcionales

```text
status=open
priority=high
email=cliente@example.com
```

### Respuesta 200

```json
{
  "success": true,
  "count": 1,
  "tickets": []
}
```

## Obtener ticket por ID

```http
GET /tickets/{id}
```

Acceso: soporte autenticado.

### Respuesta 200

```json
{
  "success": true,
  "ticket": {
    "ticketId": "TKT-20260604-A1B2C3D4",
    "status": "open"
  }
}
```

## Seguimiento público

```http
GET /tickets/track/{id}
```

Acceso: público.

Devuelve una vista reducida con estado, asunto, prioridad, agente asignado, historial de estados y respuestas al cliente.

## Actualizar ticket

```http
PUT /tickets/{id}/update
```

Acceso: soporte autenticado.

### Asignar agente

```json
{
  "actor": "soporte@example.com",
  "assignee": "soporte@example.com",
  "assigneeEmail": "soporte@example.com",
  "assigneeName": "Agente Soporte"
}
```

Cuando un ticket está en `open` y se asigna agente, el sistema cambia automáticamente a `assigned`.

### Cambiar estado

```json
{
  "actor": "Agente Soporte",
  "status": "in-progress",
  "reason": "Se inicia revisión del caso."
}
```

Transiciones válidas:

| Desde | Hacia |
|---|---|
| `open` | `assigned` mediante asignación de agente |
| `assigned` | `in-progress` |
| `in-progress` | `resolved` |
| `resolved` | `closed` |

### Agregar nota interna

```json
{
  "actor": "Agente Soporte",
  "note": "Se valida el caso con el área técnica."
}
```

### Responder al cliente

```json
{
  "actor": "Agente Soporte",
  "customerReply": "Hemos revisado tu caso y ya puedes intentar nuevamente.",
  "authorType": "support"
}
```

## Respuesta pública del cliente

```http
PUT /tickets/{id}/reply
```

Acceso: público.

```json
{
  "actor": "Cliente",
  "customerReply": "Ya me funcionó, muchas gracias.",
  "problemSolved": "yes"
}
```

Valores válidos para `problemSolved`: `yes`, `no`, `partial`.

---

# Agentes

## Listar agentes

```http
GET /agents
```

Acceso: soporte autenticado.

### Respuesta 200

```json
{
  "success": true,
  "agents": [],
  "count": 0,
  "currentUser": {
    "email": "admin@example.com",
    "role": "admin",
    "name": "Administrador",
    "isAdmin": true
  }
}
```

## Crear agente

```http
POST /agents
```

Acceso: `admin` o `supervisor`.

```json
{
  "name": "Agente Soporte",
  "email": "agente@example.com",
  "role": "agent",
  "password": "Temporal123!"
}
```

Roles válidos:

```text
agent
senior_agent
supervisor
admin
```

Política de contraseña:

- Mínimo 8 caracteres.
- Al menos una minúscula.
- Al menos una mayúscula.
- Al menos un número.
- Al menos un símbolo.

## Eliminar agente

```http
DELETE /agents/{id}
```

Acceso: `admin` o `supervisor`.

Elimina el registro de DynamoDB y el usuario asociado en Cognito si existe.

---

# Códigos de estado comunes

| Código | Significado |
|---:|---|
| 200 | Operación exitosa. |
| 201 | Recurso creado. |
| 400 | Solicitud inválida. |
| 401 | Token ausente o inválido. |
| 403 | No autorizado. |
| 404 | Recurso no encontrado. |
| 409 | Conflicto, por ejemplo agente duplicado. |
| 500 | Error interno o error de AWS. |
