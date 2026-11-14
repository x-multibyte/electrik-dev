"""Unit tests for Google ADK 2.0 A2A microservice contract and runner execution."""

from __future__ import annotations

import asyncio
import ast
import importlib.util
import pathlib
import sys
import types
import unittest

ADK_DIR = pathlib.Path(__file__).resolve().parent
ROOT_DIR = ADK_DIR.parent


def _install_adk_test_stubs() -> dict[str, object]:
    """Install lightweight in-memory stubs for google-adk, genai, fastapi, and uvicorn."""
    created_agents: list[dict[str, object]] = []

    class FakeAgent:
        def __init__(self, **kwargs: object) -> None:
            self.kwargs = kwargs
            self.name = str(kwargs.get("name", "agent"))
            self.description = str(kwargs.get("description", ""))
            created_agents.append(kwargs)

    class FakeSequentialAgent(FakeAgent):
        pass

    class FakeSession:
        def __init__(self, state: dict[str, object]) -> None:
            self.state = dict(state)

    class FakeInMemorySessionService:
        def __init__(self) -> None:
            self.sessions: dict[tuple[str, str, str], FakeSession] = {}

        async def get_session(
            self, *, app_name: str, user_id: str, session_id: str
        ) -> FakeSession | None:
            return self.sessions.get((app_name, user_id, session_id))

        async def create_session(
            self,
            *,
            app_name: str,
            user_id: str,
            session_id: str,
            state: dict[str, object] | None = None,
        ) -> FakeSession:
            session = FakeSession(state or {})
            self.sessions[(app_name, user_id, session_id)] = session
            return session

    class FakeEvent:
        def __init__(self, text: str) -> None:
            self.content = types.SimpleNamespace(
                parts=[types.SimpleNamespace(text=text)]
            )

        def is_final_response(self) -> bool:
            return True

    class FakeRunner:
        def __init__(self, *, agent: object, app_name: str, session_service: FakeInMemorySessionService) -> None:
            self.agent = agent
            self.app_name = app_name
            self.session_service = session_service

        async def run_async(
            self, *, user_id: str, session_id: str, new_message: object
        ):
            session = self.session_service.sessions[(self.app_name, user_id, session_id)]
            prompt_text = getattr(getattr(new_message, "parts", [types.SimpleNamespace(text="")])[0], "text", "")
            team_id = session.state.get("tenant_team_id")
            session.state["final_output"] = f"Synthesized ADK Runner output for team {team_id}: {prompt_text}"
            yield FakeEvent(str(session.state["final_output"]))

    class FakeHTTPException(Exception):
        def __init__(self, status_code: int, detail: object) -> None:
            super().__init__(str(detail))
            self.status_code = status_code
            self.detail = detail

    class FakeRequest:
        def __init__(self, body: dict[str, object]) -> None:
            self._body = body

        async def json(self) -> dict[str, object]:
            return self._body

    class FakeFastAPI:
        def __init__(self, **_: object) -> None:
            self.routes: dict[str, object] = {}

        def get(self, path: str):
            def decorator(fn):
                self.routes[f"GET {path}"] = fn
                return fn
            return decorator

        def post(self, path: str):
            def decorator(fn):
                self.routes[f"POST {path}"] = fn
                return fn
            return decorator

    google_mod = types.ModuleType("google")
    google_adk_mod = types.ModuleType("google.adk")
    google_adk_agents_mod = types.ModuleType("google.adk.agents")
    google_adk_agents_mod.LlmAgent = FakeAgent  # type: ignore[attr-defined]
    google_adk_agents_mod.SequentialAgent = FakeSequentialAgent  # type: ignore[attr-defined]

    google_adk_runners_mod = types.ModuleType("google.adk.runners")
    google_adk_runners_mod.Runner = FakeRunner  # type: ignore[attr-defined]

    google_adk_sessions_mod = types.ModuleType("google.adk.sessions")
    google_adk_sessions_mod.InMemorySessionService = FakeInMemorySessionService  # type: ignore[attr-defined]

    google_adk_tools_mod = types.ModuleType("google.adk.tools")
    google_adk_tools_mod.google_search = object()  # type: ignore[attr-defined]

    google_genai_mod = types.ModuleType("google.genai")
    google_genai_types_mod = types.ModuleType("google.genai.types")
    google_genai_types_mod.Part = types.SimpleNamespace(from_text=lambda text="": types.SimpleNamespace(text=text))  # type: ignore[attr-defined]
    google_genai_types_mod.Content = lambda role="user", parts=None: types.SimpleNamespace(role=role, parts=parts or [])  # type: ignore[attr-defined]

    fastapi_mod = types.ModuleType("fastapi")
    fastapi_mod.FastAPI = FakeFastAPI  # type: ignore[attr-defined]
    fastapi_mod.Header = lambda default=None, **_: default  # type: ignore[attr-defined]
    fastapi_mod.HTTPException = FakeHTTPException  # type: ignore[attr-defined]
    fastapi_mod.Request = FakeRequest  # type: ignore[attr-defined]

    uvicorn_mod = types.ModuleType("uvicorn")
    uvicorn_mod.run = lambda *_, **__: None  # type: ignore[attr-defined]

    modules = {
        "google": google_mod,
        "google.adk": google_adk_mod,
        "google.adk.agents": google_adk_agents_mod,
        "google.adk.runners": google_adk_runners_mod,
        "google.adk.sessions": google_adk_sessions_mod,
        "google.adk.tools": google_adk_tools_mod,
        "google.genai": google_genai_mod,
        "google.genai.types": google_genai_types_mod,
        "fastapi": fastapi_mod,
        "uvicorn": uvicorn_mod,
    }
    for name, mod in modules.items():
        sys.modules[name] = mod

    return {"FakeRequest": FakeRequest, "FakeHTTPException": FakeHTTPException}


class AdkA2aServiceContractTest(unittest.TestCase):
    def test_agent_uses_adk_runner_and_not_nonexistent_sequential_run(self) -> None:
        agent_path = ADK_DIR / "agent.py"
        self.assertTrue(agent_path.is_file(), "adk_service/agent.py must exist")
        source = agent_path.read_text(encoding="utf-8")
        ast.parse(source)
        self.assertIn("/.well-known/agent.json", source)
        self.assertIn("/a2a/tasks/send", source)
        self.assertIn("SequentialAgent", source)
        self.assertIn("InMemorySessionService", source)
        self.assertIn("Runner", source)
        self.assertIn("run_async", source)
        self.assertNotIn("root_agent." + "run(", source)
        self.assertIn("electrik_triage_agent", source)
        self.assertIn("electrik_synthesis_agent", source)

    def test_send_a2a_task_executes_runner_and_enforces_auth_and_tenant_boundaries(self) -> None:
        stubs = _install_adk_test_stubs()
        spec = importlib.util.spec_from_file_location("electrik_adk_agent_under_test", ADK_DIR / "agent.py")
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        FakeRequest = stubs["FakeRequest"]
        FakeHTTPException = stubs["FakeHTTPException"]

        module.ADK_A2A_API_KEY = "adk-secret"
        module.ADK_ENV = "production"

        result = asyncio.run(
            module.send_a2a_task(
                FakeRequest(
                    {
                        "id": "task-77",
                        "message": {"role": "user", "parts": [{"text": "Inspect tenant invoices"}]},
                        "metadata": {"team_id": 15},
                    }
                ),
                x_electrik_team_id="15",
                x_a2a_api_key="adk-secret",
            )
        )
        self.assertEqual(result["status"], "completed")
        self.assertEqual(result["metadata"]["team_id"], 15)
        self.assertIn("Synthesized ADK Runner output for team 15", result["message"]["parts"][0]["text"])

        with self.assertRaises(FakeHTTPException) as bad_int:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-bad-int",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                        }
                    ),
                    x_electrik_team_id="15abc",
                    x_a2a_api_key="adk-secret",
                )
            )
        self.assertEqual(bad_int.exception.status_code, 422)

        with self.assertRaises(FakeHTTPException) as mismatch:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-mismatch",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                            "metadata": {"team_id": 99},
                        }
                    ),
                    x_electrik_team_id="15",
                    x_a2a_api_key="adk-secret",
                )
            )
        self.assertEqual(mismatch.exception.status_code, 422)
        self.assertEqual(mismatch.exception.detail["error"]["code"], "TENANT_CONTEXT_MISMATCH")

        module.ADK_A2A_API_KEY = ""
        module.ADK_ENV = "production"
        with self.assertRaises(FakeHTTPException) as prod_unconfigured:
            asyncio.run(
                module.send_a2a_task(
                    FakeRequest(
                        {
                            "id": "task-unconfigured",
                            "message": {"role": "user", "parts": [{"text": "Hello"}]},
                        }
                    ),
                    x_electrik_team_id="15",
                    x_a2a_api_key="",
                )
            )
        self.assertEqual(prod_unconfigured.exception.status_code, 503)

    def test_single_canonical_setup_script_exists_and_preserves_boost_guidelines(self) -> None:
        duplicate_script = ADK_DIR / "setup_electrik_agent_kit.sh"
        canonical_script = ROOT_DIR / "setup_electrik_agent_kit.sh"
        self.assertFalse(duplicate_script.exists(), "Duplicate adk_service/setup_electrik_agent_kit.sh must be removed")
        self.assertTrue(canonical_script.is_file(), "Canonical setup_electrik_agent_kit.sh must exist at repository root")
        content = canonical_script.read_text(encoding="utf-8")
        self.assertNotIn("root_agent." + "run(", content)
        self.assertNotIn("X-Tenant-" + "ID", content)
        self.assertIn("<laravel-boost-guidelines>", content)
        self.assertIn("TenantCopilotAgent", content)
        self.assertIn("RunTenantAdkWorkflowJob", content)


if __name__ == "__main__":
    unittest.main()
