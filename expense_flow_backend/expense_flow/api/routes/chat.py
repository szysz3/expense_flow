"""WebSocket chat endpoint."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from fastapi.encoders import jsonable_encoder

from expense_flow.api.dependencies import get_chat_service
from expense_flow.config import get_config
from expense_flow.services.chat_service import ChatService

logger = logging.getLogger("expense_flow")

router = APIRouter(tags=["chat"])


@router.websocket("/api/chat")
async def chat_endpoint(
    websocket: WebSocket,
    chat_service: ChatService = Depends(get_chat_service),
) -> None:
    """WebSocket endpoint for interactive chat."""
    await websocket.accept()

    try:
        data = await websocket.receive_json()

        if "api_key" in data and data["api_key"] != get_config().api_key:
            await websocket.send_json({"error": "Invalid API key"})
            await websocket.close()
            return

        await websocket.send_json(
            {"status": "connected", "message": "Connection established"}
        )

        while True:
            data = await websocket.receive_json()
            message = data.get("message")
            conversation_id = data.get("conversation_id")

            if not message:
                await websocket.send_json({"error": "Message field is required"})
                continue

            async for chat_message in chat_service.send_message(
                message, conversation_id
            ):
                json_data = jsonable_encoder(chat_message)
                await websocket.send_json(json_data)

    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected")
    except Exception as exc:  # noqa: BLE001
        logger.error("Error in chat endpoint: %s", exc, exc_info=True)
        try:
            await websocket.send_json({"error": str(exc)})
        except Exception:  # pragma: no cover - connection already closed
            pass
