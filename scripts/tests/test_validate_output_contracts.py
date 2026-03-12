from __future__ import annotations

import sys
import unittest
from pathlib import Path


SCRIPTS_DIR = Path(__file__).resolve().parents[1]
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

from validate_output_contracts import (
    require_positive_int,
    validate_mir_graphs,
    validate_optional_typed_tasks,
    validate_span,
)


def valid_span() -> dict[str, int]:
    return {
        "start_line": 1,
        "start_col": 1,
        "end_line": 1,
        "end_col": 1,
    }


class ValidateOutputContractsTests(unittest.TestCase):
    def test_require_positive_int_rejects_boolean(self) -> None:
        with self.assertRaises(ValueError):
            require_positive_int(True, "payload.capacity")

    def test_validate_span_rejects_boolean_coordinates(self) -> None:
        with self.assertRaises(ValueError):
            validate_span(
                {
                    "start_line": True,
                    "start_col": 1,
                    "end_line": 1,
                    "end_col": 1,
                },
                "payload.span",
            )

    def test_validate_optional_typed_tasks_rejects_boolean_priority(self) -> None:
        with self.assertRaises(ValueError):
            validate_optional_typed_tasks(
                [
                    {
                        "name": "Worker",
                        "priority": False,
                        "has_explicit_priority": True,
                        "span": valid_span(),
                    }
                ],
                "typed.tasks",
            )

    def test_validate_mir_graphs_rejects_boolean_task_priority(self) -> None:
        with self.assertRaises(ValueError):
            validate_mir_graphs(
                [
                    {
                        "name": "Worker",
                        "kind": "task",
                        "entry_bb": "bb0",
                        "priority": True,
                        "has_explicit_priority": False,
                        "span": valid_span(),
                        "blocks": [],
                    }
                ],
                "mir.graphs",
            )


if __name__ == "__main__":
    unittest.main()
