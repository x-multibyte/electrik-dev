---
name: adk-a2a-bridge
description: Build and connect in-app AI agents using the Laravel AI SDK (PHP) and Google ADK 2.0 multi-agent workflows (Python/Go/TS) via the Agent2Agent (A2A) protocol and MCP.
---

# Laravel AI SDK & Google ADK 2.0 Bridge Skill

Connect in-app Laravel AI SDK agents (`App\Ai\Agents\*`) with Python Google ADK 2.0 multi-agent orchestrations (`adk_service/`) over HTTP using the Agent2Agent (A2A) JSON-RPC protocol.

## 1. Architecture Roles
- **Laravel AI SDK (`App\Ai\`)**: Hosts runtime skill discovery (`SkillRegistry`), tenant-aware conversational agents (`TenantCopilotAgent`), A2A outbound tool calls (`RemoteAdkAgentTool`), and inbound A2A server endpoints (`A2aServerController` + `/.well-known/agent.json`).
- **Google ADK 2.0 (`adk_service/`)**: Hosts complex `SequentialAgent` / `ParallelAgent` / `LoopAgent` pipelines and A2A Starlette ASGI endpoints exposed to Laravel.

## 2. Tenant Context & Auth Propagation
- Every cross-service A2A call MUST propagate the canonical `X-Electrik-Team-Id` header and matching `metadata.team_id` payload field plus `X-A2A-Api-Key` header authentication (`config('services.adk.server_api_key')` / `ADK_A2A_API_KEY`).
- Inbound A2A requests to `/api/a2a/tasks/send` (Laravel) or `/a2a/tasks/send` (ADK) without a valid positive integer `X-Electrik-Team-Id` / `metadata.team_id` MUST return `422` (`MISSING_TENANT_CONTEXT` or `TENANT_CONTEXT_MISMATCH`), invalid API keys MUST return `401` (`INVALID_A2A_API_KEY`), and unconfigured server keys outside local/testing MUST fail closed with `503` (`A2A_AUTH_NOT_CONFIGURED`).
- Metered AI workflow executions MUST run through queued jobs (`RunTenantAdkWorkflowJob`) and report usage on the owning `Team`.
