#!/usr/bin/env python3
"""Validate emitted mir-v1 structure for the PR05 sequential subset."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


TERMINATORS = {"jump", "branch", "return"}
FORBIDDEN_OPS = {"if", "while", "for"}


class ValidationError(Exception):
    pass


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValidationError(message)


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_span(value: Any, where: str) -> None:
    require(isinstance(value, dict), f"{where}: span must be an object")
    for key in ("start_line", "start_col", "end_line", "end_col"):
        require(isinstance(value.get(key), int), f"{where}: missing {key}")


def is_operand_dict(value: Any) -> bool:
    return isinstance(value, dict) and "kind" in value and "span" in value


def validate_operand(value: dict[str, Any], where: str) -> None:
    validate_span(value.get("span"), f"{where}.span")
    kind = value.get("kind")
    require(isinstance(kind, str), f"{where}: missing operand kind")
    if kind not in {"scope_enter", "scope_exit"}:
        require(isinstance(value.get("type"), str), f"{where}: missing operand type")
    if kind in FORBIDDEN_OPS:
        raise ValidationError(f"{where}: forbidden high-level MIR op {kind}")
    if value.get("op") == "and then":
        raise ValidationError(f"{where}: `and then` must lower into CFG, not remain in MIR operands")
    for key in ("left", "right", "expr", "prefix", "callee", "target", "value", "condition"):
        child = value.get(key)
        if is_operand_dict(child):
            validate_operand(child, f"{where}.{key}")
    for key in ("indices", "args", "fields"):
        child = value.get(key)
        if isinstance(child, list):
            for index, item in enumerate(child):
                if isinstance(item, dict) and "expr" in item:
                    validate_span(item.get("span"), f"{where}.{key}[{index}].span")
                    validate_operand(item["expr"], f"{where}.{key}[{index}].expr")
                elif is_operand_dict(item):
                    validate_operand(item, f"{where}.{key}[{index}]")


def validate_block(block: dict[str, Any], valid_ids: set[str], where: str) -> None:
    require(isinstance(block.get("id"), str), f"{where}: missing block id")
    validate_span(block.get("span"), f"{where}.span")
    require(isinstance(block.get("ops"), list), f"{where}: ops must be a list")
    for index, op in enumerate(block["ops"]):
        require(isinstance(op, dict), f"{where}.ops[{index}]: op must be an object")
        kind = op.get("kind")
        require(isinstance(kind, str), f"{where}.ops[{index}]: missing kind")
        if kind in FORBIDDEN_OPS:
            raise ValidationError(f"{where}.ops[{index}]: high-level control op `{kind}` leaked into MIR")
        validate_span(op.get("span"), f"{where}.ops[{index}].span")
        for key in ("target", "value"):
            child = op.get(key)
            if is_operand_dict(child):
                validate_operand(child, f"{where}.ops[{index}].{key}")
    terminator = block.get("terminator")
    require(isinstance(terminator, dict), f"{where}: every block must have a terminator")
    kind = terminator.get("kind")
    require(kind in TERMINATORS, f"{where}: invalid terminator kind {kind!r}")
    validate_span(terminator.get("span"), f"{where}.terminator.span")
    if kind == "jump":
        require(terminator.get("target") in valid_ids, f"{where}: jump target missing or invalid")
    elif kind == "branch":
        require(terminator.get("true_target") in valid_ids, f"{where}: branch true_target missing or invalid")
        require(terminator.get("false_target") in valid_ids, f"{where}: branch false_target missing or invalid")
        validate_operand(terminator.get("condition"), f"{where}.terminator.condition")
    elif kind == "return" and terminator.get("value") is not None:
        validate_operand(terminator["value"], f"{where}.terminator.value")


def validate_graph(graph: dict[str, Any], graph_index: int) -> None:
    where = f"graphs[{graph_index}]"
    require(isinstance(graph.get("name"), str), f"{where}: missing graph name")
    require(isinstance(graph.get("locals"), list), f"{where}: locals must be a list")
    require(isinstance(graph.get("blocks"), list) and graph["blocks"], f"{where}: blocks must be a non-empty list")
    expected_ids = [f"bb{i}" for i in range(len(graph["blocks"]))]
    actual_ids = [block.get("id") for block in graph["blocks"]]
    require(actual_ids == expected_ids, f"{where}: block ids must be deterministic {expected_ids}, got {actual_ids}")
    valid_ids = set(actual_ids)
    require(graph.get("entry_bb") in valid_ids, f"{where}: entry block id missing or invalid")
    for index, local in enumerate(graph["locals"]):
        local_where = f"{where}.locals[{index}]"
        require(isinstance(local.get("id"), str), f"{local_where}: missing local id")
        require(isinstance(local.get("name"), str), f"{local_where}: missing local name")
        validate_span(local.get("span"), f"{local_where}.span")
        require(isinstance(local.get("type"), dict), f"{local_where}: missing local type")
    for index, block in enumerate(graph["blocks"]):
        validate_block(block, valid_ids, f"{where}.blocks[{index}]")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mir_json", type=Path)
    args = parser.parse_args()

    payload = read_json(args.mir_json)
    require(payload.get("format") == "mir-v1", f"{args.mir_json}: expected format mir-v1")
    graphs = payload.get("graphs")
    require(isinstance(graphs, list) and graphs, f"{args.mir_json}: graphs must be a non-empty list")
    for index, graph in enumerate(graphs):
        validate_graph(graph, index)
    print(f"validate_mir_output: OK ({args.mir_json})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidationError as exc:
        print(f"validate_mir_output: ERROR: {exc}")
        raise SystemExit(1)
