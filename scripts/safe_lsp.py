#!/usr/bin/env python3
"""Disposable PR11.1 diagnostics-only LSP shim."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlparse

from _lib.harness_common import ensure_sdkroot, run_capture
from _lib.pr111_language_eval import REPO_ROOT, safec_path


WINDOWS_DRIVE_URI_RE = re.compile(r"^/[A-Za-z]:")


def file_uri_to_path(uri: str) -> Path | None:
    parsed = urlparse(uri)
    if parsed.scheme != "file":
        return None
    netloc = unquote(parsed.netloc)
    decoded_path = unquote(parsed.path)
    if netloc and netloc.lower() != "localhost":
        return Path(f"//{netloc}{decoded_path}")
    if WINDOWS_DRIVE_URI_RE.match(decoded_path):
        return Path(decoded_path[1:])
    return Path(decoded_path)


def synthetic_diagnostic(path: Path, reason: str, message: str) -> dict[str, Any]:
    return {
        "code": reason,
        "message": message,
        "severity": 1,
        "range": {
            "start": {"line": 0, "character": 0},
            "end": {"line": 0, "character": 1},
        },
        "source": "safec",
    }


def span_to_range(span: dict[str, Any] | None) -> dict[str, dict[str, int]]:
    if not isinstance(span, dict):
        return {
            "start": {"line": 0, "character": 0},
            "end": {"line": 0, "character": 1},
        }
    start_line = max(int(span.get("start_line", 1)) - 1, 0)
    start_col = max(int(span.get("start_col", 1)) - 1, 0)
    end_line = max(int(span.get("end_line", start_line + 1)) - 1, start_line)
    end_col = max(int(span.get("end_col", start_col + 1)), start_col + 1)
    return {
        "start": {"line": start_line, "character": start_col},
        "end": {"line": end_line, "character": end_col},
    }


def diagnostic_to_lsp(diagnostic: dict[str, Any]) -> dict[str, Any]:
    return {
        "code": diagnostic.get("reason", "safe_diagnostic"),
        "message": diagnostic.get("message", "Safe diagnostic"),
        "severity": 1,
        "range": span_to_range(diagnostic.get("span")),
        "source": "safec",
    }


def read_diag_payload(path: Path) -> list[dict[str, Any]]:
    env = ensure_sdkroot(os.environ.copy())
    completed = run_capture(
        [str(safec_path()), "check", "--diag-json", str(path)],
        cwd=REPO_ROOT,
        env=env,
    )
    if completed.stdout:
        try:
            payload = json.loads(completed.stdout)
        except json.JSONDecodeError:
            return [
                synthetic_diagnostic(
                    path,
                    "lsp_bridge_failure",
                    f"failed to parse safec diagnostics JSON: {completed.stdout.strip()}",
                )
            ]
        diagnostics = payload.get("diagnostics")
        if payload.get("format") == "diagnostics-v0" and isinstance(diagnostics, list):
            return [diagnostic_to_lsp(item) for item in diagnostics if isinstance(item, dict)]
    if completed.returncode == 0:
        return []
    stderr = completed.stderr.strip() or "safec check failed without diagnostics-v0 output"
    return [synthetic_diagnostic(path, "lsp_bridge_failure", stderr)]


class JsonRpcReader:
    def __init__(self, stream: Any) -> None:
        self.stream = stream

    def read_message(self) -> dict[str, Any] | None:
        headers: dict[str, str] = {}
        while True:
            line = self.stream.readline()
            if not line:
                return None
            if line in {b"\r\n", b"\n"}:
                break
            key, _, value = line.decode("utf-8").partition(":")
            headers[key.strip().lower()] = value.strip()
        length = int(headers.get("content-length", "0"))
        if length <= 0:
            return None
        body = self.stream.read(length)
        if not body:
            return None
        return json.loads(body.decode("utf-8"))


class JsonRpcWriter:
    def __init__(self, stream: Any) -> None:
        self.stream = stream

    def send(self, payload: dict[str, Any]) -> None:
        body = json.dumps(payload, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
        header = f"Content-Length: {len(body)}\r\n\r\n".encode("utf-8")
        self.stream.write(header)
        self.stream.write(body)
        self.stream.flush()


class SafeLanguageServer:
    def __init__(self, writer: JsonRpcWriter) -> None:
        self.writer = writer
        self.shutdown_requested = False

    def send(self, payload: dict[str, Any]) -> None:
        self.writer.send(payload)

    def publish_diagnostics(self, uri: str, diagnostics: list[dict[str, Any]]) -> None:
        self.send(
            {
                "jsonrpc": "2.0",
                "method": "textDocument/publishDiagnostics",
                "params": {
                    "uri": uri,
                    "diagnostics": diagnostics,
                },
            }
        )

    def check_uri(self, uri: str) -> None:
        path = file_uri_to_path(uri)
        if path is None:
            self.publish_diagnostics(uri, [])
            return
        self.publish_diagnostics(uri, read_diag_payload(path))

    def handle_request(self, message: dict[str, Any]) -> None:
        method = message.get("method")
        request_id = message.get("id")
        if method == "initialize":
            self.send(
                {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "capabilities": {
                            "textDocumentSync": {
                                "openClose": True,
                                "change": 0,
                                "save": {"includeText": False},
                            }
                        }
                    },
                }
            )
            return
        if method == "shutdown":
            self.shutdown_requested = True
            self.send({"jsonrpc": "2.0", "id": request_id, "result": None})
            return
        self.send(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "error": {
                    "code": -32601,
                    "message": f"unsupported method: {method}",
                },
            }
        )

    def handle_notification(self, message: dict[str, Any]) -> bool:
        method = message.get("method")
        params = message.get("params") or {}
        if method in {"initialized", "$/setTrace"}:
            return True
        if method in {"textDocument/didOpen", "textDocument/didSave"}:
            text_document = params.get("textDocument") or {}
            uri = text_document.get("uri")
            if isinstance(uri, str):
                self.check_uri(uri)
            return True
        if method == "textDocument/didClose":
            text_document = params.get("textDocument") or {}
            uri = text_document.get("uri")
            if isinstance(uri, str):
                self.publish_diagnostics(uri, [])
            return True
        if method == "exit":
            return False
        return True

    def process_message(self, message: dict[str, Any]) -> bool:
        if "id" in message:
            self.handle_request(message)
            return True
        return self.handle_notification(message)


def main() -> int:
    reader = JsonRpcReader(sys.stdin.buffer)
    writer = JsonRpcWriter(sys.stdout.buffer)
    server = SafeLanguageServer(writer)
    while True:
        message = reader.read_message()
        if message is None:
            return 0
        if not server.process_message(message):
            return 0 if server.shutdown_requested else 1


if __name__ == "__main__":
    raise SystemExit(main())
