"""
Prueba el modelo qwen2.5:3b en Ollama (Docker en localhost:11434).
Requiere: pip install ollama
"""
from __future__ import annotations

import os
import sys

MODEL = os.environ.get("OLLAMA_MODEL", "qwen2.5:3b")
HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")


def _extract_reply_text(r: object) -> str:
    if isinstance(r, dict):
        msg = r.get("message") or {}
        return (msg.get("content") or "").strip() if isinstance(msg, dict) else ""
    msg = getattr(r, "message", None)
    if msg is not None:
        c = getattr(msg, "content", None)
        if c is not None:
            return str(c).strip()
    return ""


def main() -> int:
    try:
        import ollama
    except ImportError:
        print("Instala: pip install ollama", file=sys.stderr)
        return 1

    client = ollama.Client(host=HOST)
    try:
        r = client.chat(
            model=MODEL,
            messages=[{"role": "user", "content": "Responde solo: ok"}],
        )
    except Exception as e:
        err = str(e).lower()
        print(f"Error: {e}", file=sys.stderr)
        if "not found" in err or "404" in err:
            print(
                "\nDescarga el modelo en el contenedor:\n"
                "  docker exec ollama-local ollama pull qwen2.5:3b",
                file=sys.stderr,
            )
        elif "connection" in err or "refused" in err:
            print(
                "\nLevanta Ollama:\n"
                "  docker compose -f docker-compose.ollama.yml up -d",
                file=sys.stderr,
            )
        return 1

    text = _extract_reply_text(r)
    print(f"Host: {HOST}")
    print(f"Modelo: {MODEL}")
    print(f"Respuesta: {text.strip()}")
    print("Ollama OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
