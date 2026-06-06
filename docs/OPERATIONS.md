# Operación, monitoreo y solución de problemas

## Logs

Cada Lambda tiene un Log Group en CloudWatch con formato:

```text
/aws/lambda/{function_name}
```

Funciones principales:

```text
create-ticket
get-tickets
update-ticket
agents
```

## Alarmas CloudWatch

El proyecto define alarmas para:

- Errores de Lambda (`Errors >= 1`).
- Duración alta de Lambda (`Duration > 10000 ms`).

Estas alarmas ayudan a detectar fallas de ejecución o lentitud, pero no reemplazan un sistema completo de observabilidad.

## Problemas comunes

### El frontend muestra que `API_CONFIG.BASE_URL` no está configurado

Causa probable: se abrió el frontend local sin editar `api-config.js`, o el archivo generado por Terraform no fue publicado en S3.

Solución:

```bash
terraform apply -var-file=environments/development.tfvars
terraform output api_endpoint
```

Verifica que el archivo `api-config.js` en el bucket tenga la URL real del API.

### Error CORS o `Failed to fetch`

Posibles causas:

- API Gateway no tiene método `OPTIONS` para el endpoint.
- El authorizer de Cognito rechazó la petición antes de llegar a Lambda.
- El frontend está apuntando a una URL incorrecta.

Revisar:

- URL base en `api-config.js`.
- Headers `Access-Control-Allow-Origin`.
- Gateway Responses `DEFAULT_4XX` y `DEFAULT_5XX`.

### No puedo iniciar sesión

Posibles causas:

- Usuario no existe en Cognito.
- Contraseña temporal vencida.
- El App Client ID no coincide con el frontend.
- El usuario debe cambiar contraseña en primer ingreso.

Revisar outputs:

```bash
terraform output cognito_user_pool_id
terraform output cognito_client_id
```

### No se cargan imágenes de evidencia

Posibles causas:

- Imagen mayor a 2 MB.
- Tipo de archivo no inicia con `image/`.
- Bucket de evidencias sin permisos correctos.
- Variable `EVIDENCE_BUCKET` no configurada.

### Los tickets no aparecen en el panel

Revisar:

- Tabla DynamoDB correcta en variable `TABLE_NAME`.
- Permisos IAM de la Lambda `get_tickets`.
- Token de Cognito válido.
- Filtros activos en el frontend.

### El agente no se crea

Revisar:

- Contraseña cumple política de Cognito.
- Email no está duplicado en DynamoDB o Cognito.
- Lambda `agents` tiene permisos `cognito-idp:AdminCreateUser` y `AdminSetUserPassword`.
- Variable `COGNITO_USER_POOL_ID` configurada.

## Mantenimiento recomendado

- Rotar credenciales AWS usadas en CI/CD.
- Revisar CloudWatch Logs después de cada despliegue.
- Habilitar budgets de AWS para controlar costos.
- Revisar permisos públicos de buckets S3.
- Configurar retención de logs según necesidades del proyecto.

## Métricas útiles

| Métrica | Servicio | Uso |
|---|---|---|
| `Errors` | Lambda | Detectar errores de ejecución. |
| `Duration` | Lambda | Detectar lentitud. |
| `4XXError` | API Gateway | Errores de cliente o autenticación. |
| `5XXError` | API Gateway | Errores del backend/API. |
| `ConsumedReadCapacityUnits` | DynamoDB | Lecturas consumidas. |
| `ConsumedWriteCapacityUnits` | DynamoDB | Escrituras consumidas. |
