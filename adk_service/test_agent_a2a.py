"""Unit test for the Google ADK 2.0 A2A microservice contract."""

import ast
import pathlib
import unittest


class AdkA2aServiceStructureTest(unittest.TestCase):
    def test_agent_exposes_a2a_endpoints_and_sequential_orchestrator(self) -> None:
        agent_path = pathlib.Path(__file__).parent / "agent.py"
        self.assertTrue(agent_path.is_file(), "adk_service/agent.py must exist")
        source = agent_path.read_text(encoding="utf-8")
        ast.parse(source)
        self.assertIn("/.well-known/agent.json", source)
        self.assertIn("/a2a/tasks/send", source)
        self.assertIn("SequentialAgent", source)
        self.assertIn("electrik_triage_agent", source)
        self.assertIn("electrik_synthesis_agent", source)


if __name__ == "__main__":
    unittest.main()
