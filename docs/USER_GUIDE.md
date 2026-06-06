# Guía de usuario

## Roles del sistema

| Rol | Descripción |
|---|---|
| Cliente | Crea tickets y consulta seguimiento. |
| Agente de soporte | Atiende tickets asignados. |
| Supervisor | Puede gestionar agentes y revisar tickets. |

## Crear un ticket como cliente

1. Entrar al formulario público.
2. Completar nombre, correo, teléfono, categoría, prioridad, asunto y descripción.
3. Adjuntar imagen de evidencia si aplica.
4. Enviar el formulario.
5. Guardar el número de ticket generado.

## Consultar seguimiento

1. Entrar a la página de seguimiento.
2. Escribir el número de ticket.
3. Revisar estado, agente asignado, historial y respuestas.
4. Responder si el soporte solicita información adicional.

## Iniciar sesión como soporte

1. Entrar a la página de login.
2. Usar correo y contraseña de Cognito.
3. Si es el primer ingreso, Cognito puede solicitar cambio de contraseña.
4. Acceder al panel de soporte.

## Atender un ticket

1. Abrir el panel de soporte.
2. Revisar la lista de tickets.
3. Filtrar por estado, prioridad o correo si es necesario.
4. Abrir el ticket.
5. Asignar un agente.
6. Cambiar estado a `in-progress` cuando inicie la atención.
7. Agregar notas internas si aplica.
8. Responder al cliente.
9. Marcar como `resolved` cuando esté solucionado.
10. Cerrar como `closed` al finalizar.

## Estados del ticket

| Estado | Uso |
|---|---|
| `open` | Ticket creado, aún sin asignación. |
| `assigned` | Ticket asignado a un agente. |
| `in-progress` | Caso en atención. |
| `resolved` | Solución entregada. |
| `closed` | Caso cerrado. |

## Prioridades

| Prioridad | Descripción sugerida |
|---|---|
| `low` | Solicitud no crítica. |
| `medium` | Caso normal de soporte. |
| `high` | Incidente urgente o de alto impacto. |

## Categorías

| Categoría | Descripción |
|---|---|
| `technical` | Problemas técnicos. |
| `billing` | Facturación o pagos. |
| `account` | Acceso o cuenta. |
| `general` | Solicitudes generales. |
