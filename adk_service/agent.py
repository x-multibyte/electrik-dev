"""Google ADK 2.0 Multi-Agent Workflow with native A2A Server & Client."""

from __future__ import annotations

import hmac
import os
from typing import Any

import uvicorn
from fastapi import FastAPI, Header, HTTPException, Request
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import google_search
from google.genai import types

ADK_A2A_API_KEY = os.getenv("ADK_A2A_API_KEY", "")
ADK_ENV = os.getenv("ADK_ENV", "production")
LARAVEL_A2A_ENDPOINT = os.getenv(
    "LARAVEL_A2A_ENDPOINT", "http://127.0.0.1:8000/api/a2a/tasks/send"
)
MODEL_NAME = os.getenv("ADK_GEMINI_MODEL", "gemini-2.5-flash")
APP_NAME = "electrik_adk_service"

app = FastAPI(title="Electrik ADK 2.0 A2A Service", version="1.0.0")

triage_agent = LlmAgent(
    name="electrik_triage_agent",
    model=MODEL_NAME,
    description="Analyzes tenant requests, verifies team scoping, and structures execution plans.",
    instruction=(
        "You are a tenant-scoped SaaS triage specialist for an Electrik application. "
        "Classify the request priority, verify tenant boundaries, and output a structured plan."
    ),
    tools=[google_search],
    output_key="triage_plan",
)

execution_agent = LlmAgent(
    name="electrik_synthesis_agent",
    model=MODEL_NAME,
    description="Synthesizes the final grounded deliverable from the triage plan.",
    instruction=(
        "Read the {triage_plan} from session state and produce the final actionable response "
        "adhering strictly to Electrik and Slate 3 conventions."
    ),
    output_key="final_output",
)

root_agent = SequentialAgent(
    name="electrik_saas_orchestrator",
    description="End-to-end sequential multi-agent pipeline for Electrik SaaS tenants.",
    sub_agents=[triage_agent, execution_agent],
)

session_service = InMemorySessionService()
runner = Runner(
    agent=root_agent,
    app_name=APP_NAME,
    session_service=session_service,
)


def _parse_positive_team_id(value: object) -> int | None:
    """Strictly parse a positive integer team ID without accepting booleans or suffixes."""
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value > 0 else None
    if isinstance(value, str) and value.isdigit() and not value.startswith("0"):
        parsed = int(value)
        return parsed if parsed > 0 else None
    return None


@app.get("/.well-known/agent.json")
def get_agent_card() -> dict[str, Any]:
    """Serve the Google ADK A2A discovery card."""
    return {
        "$schema": "https://a2a-protocol.org/schemas/v1/agent.json",
        "name": "adk-electrik-orchestrator",
        "description": "Google ADK 2.0 multi-agent orchestrator for Electrik SaaS workflows.",
        "version": "1.0.0",
        "endpoint": "/a2a/tasks/send",
        "capabilities": {
            "streaming": False,
            "stateful": True,
        },
        "authentication": {
            "type": "apiKey",
            "header": "X-A2A-Api-Key",
        },
        "skills": [
            {
                "name": "deep_tenant_reasoning",
                "description": "Executes sequential multi-step analysis and grounded synthesis.",
            }
        ],
    }


@app.post("/a2a/tasks/send")
async def send_a2a_task(
    request: Request,
    x_electrik_team_id: str | None = Header(default=None, alias="X-Electrik-Team-Id"),
    x_a2a_api_key: str | None = Header(default=None, alias="X-A2A-Api-Key"),
) -> dict[str, Any]:
    """Execute a tenant-scoped SequentialAgent workflow via Google ADK Runner."""
    if ADK_ENV.lower() not in {"local", "development", "testing"} and not ADK_A2A_API_KEY:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "failed",
                "error": {
                    "code": "A2A_AUTH_NOT_CONFIGURED",
                    "message": "ADK_A2A_API_KEY must be configured outside local/testing environments.",
                },
            },
        )

    if ADK_A2A_API_KEY and not hmac.compare_digest(
        ADK_A2A_API_KEY, x_a2a_api_key or ""
    ):
        raise HTTPException(
            status_code=401,
            detail={
                "status": "failed",
                "error": {
                    "code": "INVALID_A2A_API_KEY",
                    "message": "Invalid or missing X-A2A-Api-Key header.",
                },
            },
        )

    body = await request.json()
    task_id = str(body.get("id") or "default")
    message = body.get("message", {})
    parts = message.get("parts", [])
    if not parts or "text" not in parts[0]:
        raise HTTPException(status_code=400, detail="Missing message.parts.0.text")

    prompt = str(parts[0]["text"])
    raw_header_team = x_electrik_team_id
    raw_meta_team = body.get("metadata", {}).get("team_id")
    has_header = raw_header_team is not None and raw_header_team != ""
    has_meta = raw_meta_team is not None and raw_meta_team != ""

    header_team_id = _parse_positive_team_id(raw_header_team) if has_header else None
    meta_team_id = _parse_positive_team_id(raw_meta_team) if has_meta else None

    if (has_header and header_team_id is None) or (has_meta and meta_team_id is None):
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "MISSING_TENANT_CONTEXT",
                    "message": "Valid positive integer X-Electrik-Team-Id header or metadata.team_id is required.",
                },
            },
        )

    if header_team_id is not None and meta_team_id is not None and header_team_id != meta_team_id:
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "TENANT_CONTEXT_MISMATCH",
                    "message": "X-Electrik-Team-Id header does not match metadata.team_id.",
                },
            },
        )

    team_id = header_team_id if header_team_id is not None else meta_team_id
    if team_id is None:
        raise HTTPException(
            status_code=422,
            detail={
                "id": task_id,
                "status": "failed",
                "error": {
                    "code": "MISSING_TENANT_CONTEXT",
                    "message": "Valid X-Electrik-Team-Id header or metadata.team_id is required.",
                },
            },
        )

    user_id = f"team-{team_id}"
    session = await session_service.get_session(
        app_name=APP_NAME, user_id=user_id, session_id=task_id
    )
    if session is None:
        session = await session_service.create_session(
            app_name=APP_NAME,
            user_id=user_id,
            session_id=task_id,
            state={"tenant_team_id": str(team_id)},
        )

    content = types.Content(role="user", parts=[types.Part.from_text(text=prompt)])
    final_response_chunks: list[str] = []
    async for event in runner.run_async(
        user_id=user_id,
        session_id=task_id,
        new_message=content,
    ):
        is_final = getattr(event, "is_final_response", None)
        if callable(is_final) and is_final():
            event_content = getattr(event, "content", None)
            for part in getattr(event_content, "parts", []) or []:
                part_text = getattr(part, "text", None)
                if part_text:
                    final_response_chunks.append(str(part_text))

    updated_session = await session_service.get_session(
        app_name=APP_NAME, user_id=user_id, session_id=task_id
    )
    state_output = (
        updated_session.state.get("final_output")
        if updated_session is not None
        else None
    )
    output_text = str(state_output or "\n".join(final_response_chunks))

    return {
        "id": task_id,
        "status": "completed",
        "message": {
            "role": "assistant",
            "parts": [{"text": output_text}],
        },
        "metadata": {
            "team_id": team_id,
            "orchestrator": root_agent.name,
            "usage": {"total_tokens": max(1, len(prompt.split()) * 4)},
        },
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
