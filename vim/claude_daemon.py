#!/usr/bin/env python3
"""Persistent Claude completion daemon for Vim.

A lightweight socket server that runs claude -p and streams the output
back to the Vim client chunk by chunk.

Socket:   ~/.cache/claude_vim_daemon.sock
Protocol: client sends prompt text + newline, server streams raw response,
          closes connection when done.
"""
import os
import sys
import signal
import socket
import subprocess
import threading

SOCKET_PATH = os.path.expanduser("~/.cache/claude_vim_daemon.sock")
PID_FILE    = os.path.expanduser("~/.cache/claude_vim_daemon.pid")

CLAUDE_CMD = [
    "claude", "-p",
    "--model", "haiku",
    "--no-session-persistence",
]


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

        proc = subprocess.Popen(
            CLAUDE_CMD + [prompt],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        while True:
            chunk = proc.stdout.read(32)
            if not chunk:
                break
            conn.sendall(chunk)
        proc.wait()
    except Exception as e:
        sys.stderr.write(f"[daemon] error: {e}\n")
    finally:
        conn.close()


def main():
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

    sys.stderr.write(f"[daemon] ready on {SOCKET_PATH}\n")

    while True:
        try:
            conn, _ = server.accept()
        except OSError:
            break
        threading.Thread(target=handle_client, args=(conn,), daemon=True).start()


if __name__ == "__main__":
    main()
