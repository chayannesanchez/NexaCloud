import base64
import json
import mimetypes
import os
import re
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
s3 = boto3.client("s3")
EVIDENCE_BUCKET = os.environ.get("EVIDENCE_BUCKET", "")
EVIDENCE_PUBLIC_BASE_URL = os.environ.get("EVIDENCE_PUBLIC_BASE_URL", "")
MAX_EVIDENCE_BYTES = 2 * 1024 * 1024

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



def _extension_from_content_type(content_type, filename=""):
    if filename and "." in filename:
        ext = "." + filename.rsplit(".", 1)[-1].lower()
        if ext in {".png", ".jpg", ".jpeg", ".webp", ".gif"}:
            return ext
    return mimetypes.guess_extension(content_type or "image/jpeg") or ".jpg"


def upload_evidence_image(ticket_id, evidence):
    """Sube imagen de evidencia a S3 y retorna metadata pública para el ticket."""
    if not evidence:
        return None
    if not EVIDENCE_BUCKET:
        raise ValueError("El bucket de evidencias no está configurado en la Lambda.")

    raw_data = evidence.get("data") or evidence.get("base64") or ""
    filename = clean_text(evidence.get("name") or "evidencia", 180)
    content_type = clean_text(evidence.get("type") or "image/jpeg", 80)

    if not content_type.startswith("image/"):
        raise ValueError("Solo se permiten archivos de imagen como evidencia.")

    if "," in raw_data and raw_data.lower().startswith("data:"):
        raw_data = raw_data.split(",", 1)[1]

    try:
        file_bytes = base64.b64decode(raw_data, validate=True)
    except Exception as exc:
        raise ValueError("La imagen de evidencia no tiene un formato base64 válido.") from exc

    if len(file_bytes) > MAX_EVIDENCE_BYTES:
        raise ValueError("La imagen supera el tamaño máximo permitido de 2 MB.")

    ext = _extension_from_content_type(content_type, filename)
    key = f"evidences/{ticket_id}/{uuid.uuid4().hex}{ext}"
    s3.put_object(
        Bucket=EVIDENCE_BUCKET,
        Key=key,
        Body=file_bytes,
        ContentType=content_type,
        CacheControl="private, max-age=0",
    )
    base_url = EVIDENCE_PUBLIC_BASE_URL.rstrip("/") if EVIDENCE_PUBLIC_BASE_URL else f"https://{EVIDENCE_BUCKET}.s3.amazonaws.com"
    return {
        "key": key,
        "url": f"{base_url}/{key}",
        "name": filename,
        "type": content_type,
        "size": len(file_bytes),
        "uploadedAt": datetime.now(timezone.utc).isoformat(),
    }

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

    evidence = None
    try:
        evidence = upload_evidence_image(ticket_id, body.get("evidenceImage"))
    except ValueError as exc:
        return response(400, {"success": False, "message": str(exc)})
    except ClientError as exc:
        return response(500, {"success": False, "message": "No se pudo subir la evidencia del ticket.", "detail": str(exc)})

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
        "attachments": 1 if evidence else int(body.get("attachments") or 0),
        "evidenceImage": evidence,
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
