# Lambda: agents/app.py
# Gestiona soportes técnicos en DynamoDB y crea usuarios de inicio de sesión en Cognito.
# Soporta: GET /agents, POST /agents, DELETE /agents/{id}.

import json
import os
import re
import uuid
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

AGENTS_TABLE = os.environ.get("AGENTS_TABLE") or os.environ.get("TABLE_NAME")
COGNITO_USER_POOL_ID = os.environ.get("COGNITO_USER_POOL_ID", "")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL", "").strip().lower()

if not AGENTS_TABLE:
    raise RuntimeError("No se configuró la variable de entorno AGENTS_TABLE/TABLE_NAME para la Lambda agents")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(AGENTS_TABLE)
cognito = boto3.client("cognito-idp") if COGNITO_USER_POOL_ID else None

VALID_ROLES = {"agent", "senior_agent", "supervisor", "admin"}
ADMIN_ROLES = {"admin", "supervisor"}
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST,DELETE",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, ensure_ascii=False, cls=DecimalEncoder),
    }


def parse_body(event):
    raw_body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        import base64
        raw_body = base64.b64decode(raw_body).decode("utf-8")
    return json.loads(raw_body)


def get_claims(event):
    """Obtiene claims del JWT validado por API Gateway Cognito Authorizer."""
    request_context = event.get("requestContext") or {}
    authorizer = request_context.get("authorizer") or {}
    return authorizer.get("claims") or {}


def get_caller_email(event):
    claims = get_claims(event)
    return str(claims.get("email") or claims.get("cognito:username") or "").strip().lower()


def find_agent_by_email(email):
    if not email:
        return None
    scan_result = table.scan(
        FilterExpression="email = :email",
        ExpressionAttributeValues={":email": email.lower()}
    )
    items = scan_result.get("Items", [])
    return items[0] if items else None


def caller_context(event):
    email = get_caller_email(event)
    agent = find_agent_by_email(email) if email else None
    role = str((agent or {}).get("role") or ("admin" if email and email == ADMIN_EMAIL else "")).strip().lower()
    return {
        "email": email,
        "role": role or None,
        "name": (agent or {}).get("name"),
        "isAdmin": bool(email and (email == ADMIN_EMAIL or role in ADMIN_ROLES)),
    }


def require_authenticated(event):
    return bool(get_caller_email(event))


def require_admin(event):
    return caller_context(event)["isAdmin"]


def validate_password(password):
    """Validación alineada con la política actual de Cognito del proyecto."""
    if len(password) < 8:
        return "La clave debe tener mínimo 8 caracteres."
    if not re.search(r"[a-z]", password):
        return "La clave debe incluir al menos una letra minúscula."
    if not re.search(r"[A-Z]", password):
        return "La clave debe incluir al menos una letra mayúscula."
    if not re.search(r"\d", password):
        return "La clave debe incluir al menos un número."
    if not re.search(r"[^A-Za-z0-9]", password):
        return "La clave debe incluir al menos un símbolo."
    return None


def create_cognito_user(email, name, password):
    """Crea un usuario permanente en Cognito para que el soporte pueda iniciar sesión."""
    if not cognito or not COGNITO_USER_POOL_ID:
        return {"created": False, "message": "COGNITO_USER_POOL_ID no está configurado; se registró solo en DynamoDB."}

    try:
        cognito.admin_create_user(
            UserPoolId=COGNITO_USER_POOL_ID,
            Username=email,
            TemporaryPassword=password,
            MessageAction="SUPPRESS",
            UserAttributes=[
                {"Name": "email", "Value": email},
                {"Name": "email_verified", "Value": "true"},
                {"Name": "name", "Value": name},
            ],
        )
        cognito.admin_set_user_password(
            UserPoolId=COGNITO_USER_POOL_ID,
            Username=email,
            Password=password,
            Permanent=True,
        )
        return {"created": True}
    except cognito.exceptions.UsernameExistsException:
        return {"error": "Ya existe un usuario de inicio de sesión con ese correo en Cognito."}
    except ClientError as exc:
        return {"error": exc.response.get("Error", {}).get("Message", str(exc))}


def delete_cognito_user(email):
    if not cognito or not COGNITO_USER_POOL_ID or not email:
        return
    try:
        cognito.admin_delete_user(UserPoolId=COGNITO_USER_POOL_ID, Username=email)
    except cognito.exceptions.UserNotFoundException:
        return
    except Exception as exc:
        print("No se pudo eliminar usuario Cognito:", str(exc))


def handler(event, context):
    method = event.get("httpMethod", "GET").upper()
    path_params = event.get("pathParameters") or {}
    agent_id = str(path_params.get("id") or "").strip()

    try:
        if method == "OPTIONS":
            return response(200, {"success": True})

        if not require_authenticated(event):
            return response(401, {"success": False, "message": "Sesión requerida para acceder a agentes."})

        current_user = caller_context(event)

        if method in {"POST", "DELETE"} and not current_user["isAdmin"]:
            return response(403, {"success": False, "message": "No tienes permisos para administrar soportes técnicos."})

        if method == "GET":
            items = []
            scan_kwargs = {}
            while True:
                result = table.scan(**scan_kwargs)
                items.extend(result.get("Items", []))
                last_key = result.get("LastEvaluatedKey")
                if not last_key:
                    break
                scan_kwargs["ExclusiveStartKey"] = last_key

            # Nunca exponer datos sensibles si llegan a existir por error.
            for item in items:
                item.pop("password", None)
                item.pop("passwordHash", None)
            items.sort(key=lambda x: x.get("createdAt", ""))
            return response(200, {"success": True, "agents": items, "count": len(items), "currentUser": current_user})

        if method == "POST":
            body = parse_body(event)
            name = str(body.get("name") or "").strip()
            email = str(body.get("email") or "").strip().lower()
            role = str(body.get("role") or "agent").strip()
            password = str(body.get("password") or "").strip()

            if not name or not email or not password:
                return response(400, {"success": False, "message": "Nombre, email y clave son obligatorios."})
            if not EMAIL_RE.match(email):
                return response(400, {"success": False, "message": "El correo electrónico no tiene un formato válido."})
            if role not in VALID_ROLES:
                return response(400, {"success": False, "message": f"Rol inválido. Válidos: {', '.join(sorted(VALID_ROLES))}"})
            password_error = validate_password(password)
            if password_error:
                return response(400, {"success": False, "message": password_error})

            scan_result = table.scan(
                FilterExpression="email = :email",
                ExpressionAttributeValues={":email": email}
            )
            if scan_result.get("Items"):
                return response(409, {"success": False, "message": "Ya existe un agente con ese email."})

            cognito_result = create_cognito_user(email, name, password)
            if cognito_result.get("error"):
                return response(409, {"success": False, "message": cognito_result["error"]})

            now = datetime.now(timezone.utc).isoformat()
            new_agent = {
                "agentId": "AGT-" + uuid.uuid4().hex[:8].upper(),
                "name": name,
                "email": email,
                "role": role,
                "assignedTickets": 0,
                "active": True,
                "loginEnabled": bool(cognito_result.get("created")),
                "createdAt": now,
                "createdBy": current_user.get("email"),
            }
            table.put_item(Item=new_agent)
            return response(201, {"success": True, "message": "Soporte registrado y usuario de acceso creado.", "agent": new_agent})

        if method == "DELETE":
            if not agent_id:
                return response(400, {"success": False, "message": "ID del agente es obligatorio."})

            existing = table.get_item(Key={"agentId": agent_id}).get("Item")
            if not existing:
                return response(404, {"success": False, "message": "Agente no encontrado."})

            table.delete_item(
                Key={"agentId": agent_id},
                ConditionExpression="attribute_exists(agentId)"
            )
            delete_cognito_user(existing.get("email"))
            return response(200, {"success": True, "message": "Agente eliminado."})

        return response(405, {"success": False, "message": "Método no permitido."})

    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code")
        if code == "ConditionalCheckFailedException":
            return response(404, {"success": False, "message": "Agente no encontrado."})
        print("AWS ClientError en agents:", str(exc))
        return response(500, {"success": False, "message": "Error interno AWS en agents.", "detail": str(exc)})
    except Exception as exc:
        print("Error inesperado en agents:", str(exc))
        return response(500, {"success": False, "message": "Error interno en Lambda agents.", "detail": str(exc)})
