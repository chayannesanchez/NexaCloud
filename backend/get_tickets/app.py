import json
import os
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


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
            "Access-Control-Allow-Methods": "OPTIONS,GET",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body, ensure_ascii=False, cls=DecimalEncoder),
    }


def normalize(value):
    return str(value or "").strip()


def is_tracking_request(event):
    """Detecta la ruta pública de seguimiento: GET /tickets/track/{id}."""
    resource = normalize(event.get("resource"))
    path = normalize(event.get("path"))
    return resource.endswith("/tickets/track/{id}") or "/tickets/track/" in path


def public_ticket_view(ticket):
    """Devuelve solo la información segura que un cliente puede consultar con su ticketId."""
    return {
        "ticketId": ticket.get("ticketId") or ticket.get("id"),
        "id": ticket.get("ticketId") or ticket.get("id"),
        "status": ticket.get("status", "open"),
        "subject": ticket.get("subject", ""),
        "category": ticket.get("category", "general"),
        "priority": ticket.get("priority", "medium"),
        "assignee": ticket.get("assignee") or None,
        "createdAt": ticket.get("createdAt"),
        "updatedAt": ticket.get("updatedAt"),
    }


def handler(event, context):
    path_params = event.get("pathParameters") or {}
    query = event.get("queryStringParameters") or {}
    ticket_id = normalize(path_params.get("id"))

    try:
        if ticket_id:
            result = table.get_item(Key={"ticketId": ticket_id})
            ticket = result.get("Item")
            if not ticket:
                return response(404, {"success": False, "message": "Ticket no encontrado."})

            if is_tracking_request(event):
                return response(200, {"success": True, "ticket": public_ticket_view(ticket)})

            return response(200, {"success": True, "ticket": ticket})

        scan_kwargs = {}
        items = []
        while True:
            result = table.scan(**scan_kwargs)
            items.extend(result.get("Items", []))
            last_key = result.get("LastEvaluatedKey")
            if not last_key:
                break
            scan_kwargs["ExclusiveStartKey"] = last_key

        status_filter = normalize(query.get("status"))
        priority_filter = normalize(query.get("priority"))
        email_filter = normalize(query.get("email")).lower()

        if status_filter:
            items = [item for item in items if item.get("status") == status_filter]
        if priority_filter:
            items = [item for item in items if item.get("priority") == priority_filter]
        if email_filter:
            items = [item for item in items if str(item.get("email", "")).lower() == email_filter]

        items.sort(key=lambda item: item.get("createdAt", ""), reverse=True)
        return response(200, {"success": True, "count": len(items), "tickets": items})
    except ClientError as exc:
        return response(500, {"success": False, "message": "No se pudieron consultar los tickets.", "detail": str(exc)})
