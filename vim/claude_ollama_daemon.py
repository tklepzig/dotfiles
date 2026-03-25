#!/usr/bin/env python3
"""Ollama completion daemon for Vim.

Calls the local Ollama API and streams completions back over a Unix socket.
Ollama must be running: https://ollama.com

Socket:   ~/.cache/ollama_vim_daemon.sock
Protocol: client sends prompt text + newline, server streams raw response,
          closes connection when done.

Default model: qwen2.5-coder:1.5b  (fast, good for code)
Override:      set g:claude_ollama_model in vim, or OLLAMA_MODEL env var.
"""
import os
import sys
import json
import signal
import socket
import threading
import http.client

SOCKET_PATH = os.path.expanduser("~/.cache/ollama_vim_daemon.sock")
PID_FILE    = os.path.expanduser("~/.cache/ollama_vim_daemon.pid")
OLLAMA_HOST = ("localhost", 11434)
DEFAULT_MODEL = os.environ.get("OLLAMA_MODEL", "qwen2.5-coder:1.5b")


def stream_ollama(prompt, model=DEFAULT_MODEL):
    """Yield raw UTF-8 chunks from the Ollama generate API."""
    conn = http.client.HTTPConnection(*OLLAMA_HOST, timeout=30)
    body = json.dumps({"model": model, "prompt": prompt, "stream": True})
    conn.request("POST", "/api/generate", body, {"Content-Type": "application/json"})
    resp = conn.getresponse()

    for raw_line in resp:
        raw_line = raw_line.strip()
        if not raw_line:
            continue
        try:
            obj = json.loads(raw_line)
        except json.JSONDecodeError:
            continue
        text = obj.get("response", "")
        if text:
            yield text.encode("utf-8")
        if obj.get("done"):
            break


def handle_client(conn):
    try:
        buf = b""
        while b"\n" not in buf:
            data = conn.recv(4096)
            if not data:
                return
            buf += data
        prompt = buf.split(b"\n", 1)[0].decode("utf-8", errors="replace").strip()
        if not prompt:
            return
        for chunk in stream_ollama(prompt):
            conn.sendall(chunk)
    except Exception as e:
        sys.stderr.write(f"[ollama-daemon] error: {e}\n")
    finally:
        conn.close()


def main():
    # Quick connectivity check
    try:
        c = http.client.HTTPConnection(*OLLAMA_HOST, timeout=3)
        c.request("GET", "/api/tags")
        c.getresponse()
    except Exception:
        sys.stderr.write(
            "[ollama-daemon] Cannot reach Ollama at localhost:11434. "
            "Is it running? Start with: ollama serve\n"
        )
        sys.exit(1)

    os.makedirs(os.path.dirname(SOCKET_PATH), exist_ok=True)

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)

    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    server.listen(5)
    os.chmod(SOCKET_PATH, 0o600)

    def shutdown(sig, frame):
        server.close()
        for p in (SOCKET_PATH, PID_FILE):
            try: os.unlink(p)
            except OSError: pass
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    sys.stderr.write(
        f"[ollama-daemon] ready on {SOCKET_PATH} (model: {DEFAULT_MODEL})\n"
    )

    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            break
        threading.Thread(target=handle_client, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    main()
