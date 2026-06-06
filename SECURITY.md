# Seguridad

## Reporte de vulnerabilidades

Si encuentras una vulnerabilidad, repórtala de forma privada al equipo responsable del repositorio. No publiques detalles sensibles en issues públicos.

## Información que no debe subirse al repositorio

- Credenciales AWS.
- Archivos locales con contraseñas o credenciales.
- Contraseñas temporales de Cognito.
- Tokens de sesión.
- Archivos `.env`.
- Llaves privadas.

## Recomendaciones para producción

1. Usar GitHub Secrets para credenciales y variables sensibles.
2. Rotar credenciales periódicamente.
3. Proteger endpoints administrativos directamente en API Gateway con Cognito Authorizer.
4. Usar CloudFront + Origin Access Control para el frontend si se requiere mayor seguridad.
5. Evitar evidencias públicas si pueden contener información sensible.
6. Configurar AWS Budgets y alarmas de uso.
7. Activar MFA en las cuentas AWS y GitHub.
8. Revisar permisos IAM bajo principio de menor privilegio.

## Manejo de contraseñas Cognito

- La contraseña temporal debe cambiarse en el primer ingreso.
- Debe cumplir mínimo 8 caracteres, mayúscula, minúscula, número y símbolo.
- No reutilizar contraseñas usadas en pruebas.


## Control de acceso administrativo

Los endpoints administrativos están protegidos con Amazon Cognito Authorizer en API Gateway. Además, las Lambdas `get_tickets`, `update_ticket` y `agents` validan de forma defensiva la presencia de claims de Cognito.

La creación y eliminación de soportes técnicos queda limitada a usuarios con rol `admin` o `supervisor`.

## GitHub Actions

No almacenes credenciales AWS ni contraseñas en archivos del repositorio. Usa GitHub Secrets para:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
TF_ADMIN_EMAIL
TF_ADMIN_TEMP_PASSWORD
```

Para producción, se recomienda migrar a OIDC con un rol IAM asumido por GitHub Actions.
