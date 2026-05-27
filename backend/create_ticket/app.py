import json
import os
import re
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

ALLOWED_CATEGORIES = {"technical", "billing", "account", "general"}
ALLOWED_PRIORITIES = {"low", "medium", "high"}
EMAIL_RE = re.compile(r"^[^\s@]+@[^\s@]+\.[^\s@]+$")


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def clean_text(value, max_len):
    if value is None:
        return ""
    return str(value).strip()[:max_len]


def parse_body(event):
    raw_body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        import base64
        raw_body = base64.b64decode(raw_body).decode("utf-8")
    return json.loads(raw_body)


def handler(event, context):
    try:
        body = parse_body(event)
    except json.JSONDecodeError:
        return response(400, {"success": False, "message": "El cuerpo de la solicitud no es JSON válido."})

    fullname = clean_text(body.get("fullname"), 120)
    email = clean_text(body.get("email"), 160).lower()
    phone = clean_text(body.get("phone"), 40)
    category = clean_text(body.get("category") or "general", 30)
    priority = clean_text(body.get("priority") or "medium", 30)
    subject = clean_text(body.get("subject"), 140)
    description = clean_text(body.get("description"), 3000)
    assignee = clean_text(body.get("assignee"), 120) or None
    status = clean_text(body.get("status") or "open", 30)

    if not fullname:
        return response(400, {"success": False, "message": "El nombre completo es obligatorio."})
    if not email or not EMAIL_RE.match(email):
        return response(400, {"success": False, "message": "El correo electrónico no es válido."})
    if category not in ALLOWED_CATEGORIES:
        return response(400, {"success": False, "message": "La categoría no es válida."})
    if priority not in ALLOWED_PRIORITIES:
        return response(400, {"success": False, "message": "La prioridad no es válida."})
    if not subject:
        return response(400, {"success": False, "message": "El asunto es obligatorio."})
    if not description:
        return response(400, {"success": False, "message": "La descripción es obligatoria."})

    now = datetime.now(timezone.utc).isoformat()
    ticket_id = f"TKT-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"

    item = {
        "id": ticket_id,
        "ticketId": ticket_id,
        "fullname": fullname,
        "email": email,
        "phone": phone,
        "category": category,
        "priority": priority,
        "subject": subject,
        "description": description,
        "status": status if status in {"open", "assigned", "in-progress", "resolved", "closed"} else "open",
        "assignee": assignee,
        "notes": [],
        "attachments": int(body.get("attachments") or 0),
        "createdAt": now,
        "updatedAt": now,
    }

    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(ticketId)",
        )
    except ClientError as exc:
        return response(500, {"success": False, "message": "No se pudo guardar el ticket.", "detail": str(exc)})

    return response(201, {"success": True, "message": "Ticket creado correctamente.", "ticketId": ticket_id, "ticket": item})
