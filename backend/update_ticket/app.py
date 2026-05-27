import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

ALLOWED_STATUS = {"open", "assigned", "in-progress", "resolved", "closed"}


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
            "Access-Control-Allow-Methods": "OPTIONS,PUT",
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


def handler(event, context):
    path_params = event.get("pathParameters") or {}
    ticket_id = str(path_params.get("id") or "").strip()
    if not ticket_id:
        return response(400, {"success": False, "message": "El ID del ticket es obligatorio."})

    try:
        body = parse_body(event)
    except json.JSONDecodeError:
        return response(400, {"success": False, "message": "El cuerpo de la solicitud no es JSON válido."})

    updates = []
    names = {}
    values = {}

    if "status" in body:
        status = str(body.get("status") or "").strip()
        if status not in ALLOWED_STATUS:
            return response(400, {"success": False, "message": "El estado no es válido."})
        names["#status"] = "status"
        values[":status"] = status
        updates.append("#status = :status")

    if "assignee" in body:
        names["#assignee"] = "assignee"
        values[":assignee"] = str(body.get("assignee") or "").strip() or None
        updates.append("#assignee = :assignee")

    now = datetime.now(timezone.utc).isoformat()
    names["#updatedAt"] = "updatedAt"
    values[":updatedAt"] = now
    updates.append("#updatedAt = :updatedAt")

    note_text = str(body.get("notes") or body.get("note") or "").strip()
    note_expression = ""
    if note_text:
        names["#notes"] = "notes"
        values[":empty_notes"] = []
        values[":new_note"] = [{
            "author": str(body.get("noteAuthor") or "Support Team").strip(),
            "time": now,
            "text": note_text[:2000],
        }]
        note_expression = ", #notes = list_append(if_not_exists(#notes, :empty_notes), :new_note)"

    if len(updates) == 1 and not note_text:
        return response(400, {"success": False, "message": "No se recibieron campos para actualizar."})

    try:
        result = table.update_item(
            Key={"ticketId": ticket_id},
            UpdateExpression="SET " + ", ".join(updates) + note_expression,
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ConditionExpression="attribute_exists(ticketId)",
            ReturnValues="ALL_NEW",
        )
        return response(200, {"success": True, "message": "Ticket actualizado correctamente.", "ticket": result.get("Attributes")})
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code")
        if code == "ConditionalCheckFailedException":
            return response(404, {"success": False, "message": "Ticket no encontrado."})
        return response(500, {"success": False, "message": "No se pudo actualizar el ticket.", "detail": str(exc)})
