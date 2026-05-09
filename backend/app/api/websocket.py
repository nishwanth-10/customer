"""
WebSocket endpoint for real-time updates to Flutter clients.
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from typing import Dict, Set
import json
import uuid

router = APIRouter(tags=["WebSocket"])

# ── Connection Manager ────────────────────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        # Map business_id → set of connected websockets
        self.active_connections: Dict[str, Set[WebSocket]] = {}

    async def connect(self, websocket: WebSocket, business_id: str):
        await websocket.accept()
        if business_id not in self.active_connections:
            self.active_connections[business_id] = set()
        self.active_connections[business_id].add(websocket)

    def disconnect(self, websocket: WebSocket, business_id: str):
        if business_id in self.active_connections:
            self.active_connections[business_id].discard(websocket)
            if not self.active_connections[business_id]:
                del self.active_connections[business_id]

    async def broadcast_to_business(self, business_id: str, message: dict):
        """Send message to all connections for a business."""
        if business_id in self.active_connections:
            dead_connections = set()
            for connection in self.active_connections[business_id].copy():
                try:
                    await connection.send_text(json.dumps(message))
                except Exception:
                    dead_connections.add(connection)
            for dead in dead_connections:
                self.active_connections[business_id].discard(dead)

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_text(json.dumps(message))


manager = ConnectionManager()


@router.websocket("/ws/{business_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    business_id: str,
    token: str = Query(None),
):
    """
    WebSocket endpoint for real-time business updates.
    Connect via: ws://host/ws/{business_id}?token=<jwt>
    
    Events emitted:
    - transaction_created: new transaction recorded
    - payment_received: payment collected
    - reminder_sent: reminder dispatched
    - customer_updated: customer data changed
    """
    await manager.connect(websocket, business_id)
    await manager.send_personal_message(
        {"event": "connected", "business_id": business_id, "message": "Real-time sync active"},
        websocket
    )

    try:
        while True:
            # Keep connection alive — receive heartbeats
            data = await websocket.receive_text()
            msg = json.loads(data)

            if msg.get("type") == "ping":
                await manager.send_personal_message({"type": "pong"}, websocket)

    except WebSocketDisconnect:
        manager.disconnect(websocket, business_id)


async def notify_business(business_id: str, event: str, data: dict):
    """Helper to broadcast events from API handlers."""
    await manager.broadcast_to_business(business_id, {"event": event, **data})
