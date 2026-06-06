# ARCHIVO MODIFICADO
# Lambda: get_tickets/app.py
# Extiende la vista pública (track) para incluir:
#   - agente asignado (nombre)
#   - respuestas al cliente (customerReplies)
#   - historial de estados (stateHistory)

import json
import os
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
AGENTS_TABLE = os.environ.get("AGENTS_TABLE")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)
agents_table = dynamodb.Table(AGENTS_TABLE) if AGENTS_TABLE else None


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
    resource = normalize(event.get("resource"))
    path = normalize(event.get("path"))
    return resource.endswith("/tickets/track/{id}") or "/tickets/track/" in path


def get_claims(event):
    request_context = event.get("requestContext") or {}
    authorizer = request_context.get("authorizer") or {}
    return authorizer.get("claims") or {}


def is_authenticated(event):
    claims = get_claims(event)
    return bool(claims.get("email") or claims.get("cognito:username"))



def find_agent_by_email(email):
    """Busca el soporte por correo para completar nombre/correo en tickets antiguos."""
    if not agents_table or not email:
        return None
    try:
        result = agents_table.scan(
            FilterExpression="email = :email",
            ExpressionAttributeValues={":email": str(email).strip().lower()}
        )
        items = result.get("Items", [])
        return items[0] if items else None
    except Exception:
        return None


def enrich_assignee(ticket):
    email = ticket.get("assigneeEmail") or ticket.get("assignee")
    name = ticket.get("assigneeName") or ticket.get("agentName") or ticket.get("supportName")
    if email and not name:
        agent = find_agent_by_email(email)
        if agent:
            name = agent.get("name")
            email = agent.get("email") or email
    return name, email

def public_ticket_view(ticket):
    """Vista pública extendida: incluye agente, respuestas y estado."""
    assignee_name, assignee_email = enrich_assignee(ticket)
    return {
        "ticketId": ticket.get("ticketId") or ticket.get("id"),
        "id": ticket.get("ticketId") or ticket.get("id"),
        "status": ticket.get("status", "open"),
        "subject": ticket.get("subject", ""),
        "category": ticket.get("category", "general"),
        "priority": ticket.get("priority", "medium"),
        "assignee": assignee_email or ticket.get("assignee") or None,
        "assigneeEmail": assignee_email or ticket.get("assigneeEmail") or ticket.get("assignee") or None,
        "assigneeName": assignee_name or ticket.get("assigneeName") or None,
        "createdAt": ticket.get("createdAt"),
        "updatedAt": ticket.get("updatedAt"),
        # Nuevos campos visibles para el cliente
        "customerReplies": ticket.get("customerReplies", []),
        "stateHistory": ticket.get("stateHistory", []),
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

            if not is_authenticated(event):
                return response(401, {"success": False, "message": "Sesión requerida para consultar el ticket administrativo."})

            return response(200, {"success": True, "ticket": ticket})

        # Listar todos (panel de soporte)
        if not is_authenticated(event):
            return response(401, {"success": False, "message": "Sesión requerida para listar tickets."})

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
