"""Google ADK 2.0 Multi-Agent Workflow with native A2A Server & Client."""

from __future__ import annotations

import hmac
import os
from typing import Any

import uvicorn
from fastapi import FastAPI, Header, HTTPException, Request
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.tools import google_search

ADK_A2A_API_KEY = os.getenv("ADK_A2A_API_KEY", "")
LARAVEL_A2A_ENDPOINT = os.getenv(
    "LARAVEL_A2A_ENDPOINT", "http://127.0.0.1:8000/api/a2a/tasks/send"
)
MODEL_NAME = os.getenv("ADK_GEMINI_MODEL", "gemini-2.5-flash")

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
    """Execute a tenant-scoped SequentialAgent workflow task over A2A."""
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
    task_id = body.get("id")
    message = body.get("message", {})
    parts = message.get("parts", [])
    if not parts or "text" not in parts[0]:
        raise HTTPException(status_code=400, detail="Missing message.parts.0.text")

    prompt = parts[0]["text"]
    raw_team_id = x_electrik_team_id or body.get("metadata", {}).get("team_id")
    try:
        team_id = int(raw_team_id) if raw_team_id is not None else 0
    except (TypeError, ValueError):
        team_id = 0

    if team_id <= 0:
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

    state: dict[str, Any] = {"tenant_team_id": str(team_id)}
    result = root_agent.run(prompt, state=state)
    output_text = state.get("final_output", str(result))

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
