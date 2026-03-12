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
    validate_optional_mir_channels,
    validate_optional_typed_channels,
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

    def test_validate_optional_typed_channels_rejects_boolean_capacity(self) -> None:
        with self.assertRaises(ValueError):
            validate_optional_typed_channels(
                [
                    {
                        "name": "Data_Ch",
                        "is_public": False,
                        "element_type": {"name": "Integer", "kind": "integer"},
                        "capacity": True,
                        "span": valid_span(),
                    }
                ],
                "typed.channels",
            )

    def test_validate_optional_mir_channels_rejects_boolean_capacity(self) -> None:
        with self.assertRaises(ValueError):
            validate_optional_mir_channels(
                [
                    {
                        "name": "Data_Ch",
                        "element_type": {"name": "Integer", "kind": "integer"},
                        "capacity": True,
                        "span": valid_span(),
                    }
                ],
                "mir.channels",
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

    def test_validate_mir_graphs_rejects_non_boolean_explicit_priority_flag(self) -> None:
        with self.assertRaises(ValueError):
            validate_mir_graphs(
                [
                    {
                        "name": "Worker",
                        "kind": "task",
                        "entry_bb": "bb0",
                        "priority": 1,
                        "has_explicit_priority": 1,
                        "span": valid_span(),
                        "blocks": [],
                    }
                ],
                "mir.graphs",
            )

    def test_validate_mir_graphs_rejects_task_return_type(self) -> None:
        with self.assertRaises(ValueError):
            validate_mir_graphs(
                [
                    {
                        "name": "Worker",
                        "kind": "task",
                        "entry_bb": "bb0",
                        "priority": 1,
                        "has_explicit_priority": False,
                        "return_type": {"name": "Integer", "kind": "integer"},
                        "span": valid_span(),
                        "blocks": [],
                    }
                ],
                "mir.graphs",
            )


if __name__ == "__main__":
    unittest.main()
