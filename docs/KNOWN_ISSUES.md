# Notas técnicas y mejoras pendientes

## Endpoints administrativos de agentes

En el Terraform actual, los endpoints `/agents` están sin authorizer de Cognito. El frontend exige sesión antes de mostrar el panel, pero para producción se recomienda reforzar la seguridad directamente en API Gateway.

Recomendación:

- Agregar Cognito Authorizer a `GET /agents`, `POST /agents` y `DELETE /agents/{id}`.
- Mantener Gateway Responses CORS para errores `4XX` y `5XX`.

## Búsqueda de agente por email

La tabla de agentes tiene `agentId` como llave primaria. Si se requiere buscar agentes por `email` de forma eficiente, se recomienda crear un índice secundario global, por ejemplo:

```text
GSI: email-index
Partition key: email
```

## Evidencias públicas

El bucket de evidencias permite lectura pública. Si la evidencia puede contener información sensible, se recomienda cambiar a acceso privado y generar URLs firmadas.

## Frontend sin build

El proyecto usa HTML/CSS/JS sin bundler. Esto simplifica la entrega académica, pero para producción se puede considerar Vite, React/Vue o un pipeline de minificación.
