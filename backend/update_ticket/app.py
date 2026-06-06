# ARCHIVO MODIFICADO
# Lambda: update_ticket/app.py
# Extiende la actualización de tickets con:
#   - Flujo estricto de estados: ABIERTO → ASIGNADO → EN PROCESO → RESUELTO → CERRADO
#   - Asignación de agente (auto-cambia estado a 'assigned')
#   - Registro de historial de cambios de estado (stateHistory)
#   - Módulo de respuestas al cliente (customerReplies)
#   - Incremento/decremento de assignedTickets en tabla de agentes

import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError

TABLE_NAME = os.environ["TABLE_NAME"]
AGENTS_TABLE = os.environ.get("AGENTS_TABLE", "")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)

# Flujo estricto de estados
STATE_FLOW = ["open", "assigned", "in-progress", "resolved", "closed"]
ALLOWED_STATUS = set(STATE_FLOW)

# Transiciones permitidas manualmente (asignación auto-gestiona open→assigned)
MANUAL_TRANSITIONS = {
    "assigned": {"in-progress"},
    "in-progress": {"resolved"},
    "resolved": {"closed"},
}


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


def get_claims(event):
    request_context = event.get("requestContext") or {}
    authorizer = request_context.get("authorizer") or {}
    return authorizer.get("claims") or {}


def get_caller_email(event):
    claims = get_claims(event)
    return str(claims.get("email") or claims.get("cognito:username") or "").strip().lower()


def update_agent_counter(agent_email, increment=True):
    """Incrementa o decrementa assignedTickets del agente en la tabla de agentes."""
    if not AGENTS_TABLE or not agent_email:
        return
    try:
        agents_table = dynamodb.Table(AGENTS_TABLE)
        scan_result = agents_table.scan(
            FilterExpression="email = :email",
            ExpressionAttributeValues={":email": agent_email.lower()}
        )
        items = scan_result.get("Items", [])
        if not items:
            return
        agent = items[0]
        delta = 1 if increment else -1
        new_count = max(0, int(agent.get("assignedTickets", 0)) + delta)
        agents_table.update_item(
            Key={"agentId": agent["agentId"]},
            UpdateExpression="SET assignedTickets = :count",
            ExpressionAttributeValues={":count": new_count}
        )
    except Exception:
        pass  # No interrumpir flujo principal por error en contador


def handler(event, context):
    path_params = event.get("pathParameters") or {}
    ticket_id = str(path_params.get("id") or "").strip()
    if not ticket_id:
        return response(400, {"success": False, "message": "El ID del ticket es obligatorio."})

    try:
        body = parse_body(event)
    except json.JSONDecodeError:
        return response(400, {"success": False, "message": "El cuerpo de la solicitud no es JSON válido."})

    # Obtener ticket actual
    try:
        current_result = table.get_item(Key={"ticketId": ticket_id})
        current_ticket = current_result.get("Item")
        if not current_ticket:
            return response(404, {"success": False, "message": "Ticket no encontrado."})
    except ClientError as exc:
        return response(500, {"success": False, "message": "Error consultando ticket.", "detail": str(exc)})

    current_status = current_ticket.get("status", "open")
    now = datetime.now(timezone.utc).isoformat()

    request_path = str(event.get("resource") or event.get("path") or "")
    is_public_reply = request_path.endswith("/reply") or "/reply" in request_path
    caller_email = get_caller_email(event)

    if not is_public_reply and not caller_email:
        return response(401, {"success": False, "message": "Sesión requerida para actualizar tickets."})

    if is_public_reply:
        body = {
            "customerReply": body.get("customerReply"),
            "actor": body.get("actor") or "Cliente",
            "authorType": "client",
            "problemSolved": body.get("problemSolved"),
        }

    actor = str(body.get("actor") or body.get("noteAuthor") or caller_email or "Support Team").strip()

    updates = []
    names = {}
    values = {}
    state_change_entry = None
    old_assignee = current_ticket.get("assignee")

    # --- ASIGNACIÓN DE AGENTE ---
    if "assignee" in body:
        new_assignee = str(body.get("assignee") or "").strip() or None
        new_assignee_email = str(body.get("assigneeEmail") or new_assignee or "").strip() or None
        new_assignee_name = str(body.get("assigneeName") or "").strip() or None
        names["#assignee"] = "assignee"
        values[":assignee"] = new_assignee
        updates.append("#assignee = :assignee")
        names["#assigneeEmail"] = "assigneeEmail"
        names["#assigneeName"] = "assigneeName"
        values[":assigneeEmail"] = new_assignee_email
        values[":assigneeName"] = new_assignee_name
        updates.append("#assigneeEmail = :assigneeEmail")
        updates.append("#assigneeName = :assigneeName")

        # Auto-cambio de estado a 'assigned' al asignar un agente
        if new_assignee and current_status in ("open",):
            names["#status"] = "status"
            values[":status"] = "assigned"
            updates.append("#status = :status")
            state_change_entry = {
                "from": current_status,
                "to": "assigned",
                "actor": actor,
                "time": now,
                "reason": f"Ticket asignado a {new_assignee_name or new_assignee}"
            }
            current_status = "assigned"

        # Actualizar contador cuando se asigna, reasigna o se deja sin asignar.
        # Esto no debe depender del cambio de estado, porque un ticket ya asignado
        # también puede cambiar de responsable.
        if new_assignee != old_assignee:
            if old_assignee:
                update_agent_counter(old_assignee, increment=False)
            if new_assignee:
                update_agent_counter(new_assignee, increment=True)

    # --- CAMBIO MANUAL DE ESTADO ---
    if "status" in body and "#status" not in names:
        new_status = str(body.get("status") or "").strip()
        if new_status not in ALLOWED_STATUS:
            return response(400, {"success": False, "message": "Estado inválido."})

        allowed_next = MANUAL_TRANSITIONS.get(current_status, set())
        if new_status != current_status and new_status not in allowed_next:
            return response(400, {
                "success": False,
                "message": f"Transición inválida: {current_status} → {new_status}. "
                           f"Permitidas: {', '.join(allowed_next) if allowed_next else 'ninguna'}"
            })

        if new_status != current_status:
            names["#status"] = "status"
            values[":status"] = new_status
            updates.append("#status = :status")
            state_change_entry = {
                "from": current_status,
                "to": new_status,
                "actor": actor,
                "time": now,
                "reason": str(body.get("reason") or "").strip() or f"Estado cambiado a {new_status}"
            }

    # --- RESPUESTA AL CLIENTE ---
    reply_expression = ""
    if "customerReply" in body:
        reply_text = str(body.get("customerReply") or "").strip()
        if reply_text:
            names["#customerReplies"] = "customerReplies"
            values[":empty_replies"] = []
            author_type = str(body.get("authorType") or "support").strip().lower()
            if author_type not in {"support", "client"}:
                author_type = "support"
            problem_solved = str(body.get("problemSolved") or "").strip().lower()
            reply_entry = {
                "author": actor,
                "authorType": author_type,
                "time": now,
                "text": reply_text[:4000],
            }
            if author_type == "client" and problem_solved in {"yes", "no", "partial"}:
                reply_entry["problemSolved"] = problem_solved
            values[":new_reply"] = [reply_entry]
            reply_expression = ", #customerReplies = list_append(if_not_exists(#customerReplies, :empty_replies), :new_reply)"
            if author_type == "client" and problem_solved in {"yes", "no", "partial"}:
                names["#customerResolution"] = "customerResolution"
                values[":customerResolution"] = problem_solved
                updates.append("#customerResolution = :customerResolution")

    # --- NOTAS INTERNAS ---
    note_expression = ""
    note_text = str(body.get("notes") or body.get("note") or "").strip()
    if note_text:
        names["#notes"] = "notes"
        values[":empty_notes"] = []
        values[":new_note"] = [{
            "author": actor,
            "time": now,
            "text": note_text[:2000],
        }]
        note_expression = ", #notes = list_append(if_not_exists(#notes, :empty_notes), :new_note)"

    # --- HISTORIAL DE ESTADOS ---
    history_expression = ""
    if state_change_entry:
        names["#stateHistory"] = "stateHistory"
        values[":empty_history"] = []
        values[":new_history_entry"] = [state_change_entry]
        history_expression = ", #stateHistory = list_append(if_not_exists(#stateHistory, :empty_history), :new_history_entry)"

    # Timestamp
    names["#updatedAt"] = "updatedAt"
    values[":updatedAt"] = now
    updates.append("#updatedAt = :updatedAt")

    if len(updates) == 1 and not note_text and not state_change_entry and not reply_expression:
        return response(400, {"success": False, "message": "No se recibieron campos para actualizar."})

    update_expr = "SET " + ", ".join(updates) + note_expression + history_expression + reply_expression

    try:
        result = table.update_item(
            Key={"ticketId": ticket_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
            ConditionExpression="attribute_exists(ticketId)",
            ReturnValues="ALL_NEW",
        )
        return response(200, {
            "success": True,
            "message": "Ticket actualizado correctamente.",
            "ticket": result.get("Attributes")
        })
    except ClientError as exc:
        code = exc.response.get("Error", {}).get("Code")
        if code == "ConditionalCheckFailedException":
            return response(404, {"success": False, "message": "Ticket no encontrado."})
        return response(500, {"success": False, "message": "No se pudo actualizar el ticket.", "detail": str(exc)})
