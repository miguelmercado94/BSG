#!/usr/bin/env python3
"""
Prueba mínima de Groq (API compatible con OpenAI): envía "hola" y muestra la respuesta.

Uso (PowerShell):
  $env:GROQ_API_KEY = "gsk_..."   # no commitees esto
  python scripts/groq_smoke_test.py

Opcional:
  $env:GROQ_MODEL = "llama-3.3-70b-versatile"
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
DEFAULT_MODEL = "llama-3.1-8b-instant"


def main() -> None:
    key = os.environ.get("GROQ_API_KEY", "").strip()
    if not key:
        print(
            "Error: define GROQ_API_KEY en el entorno (no la pegues en el repo).",
            file=sys.stderr,
        )
        sys.exit(1)

    model = os.environ.get("GROQ_MODEL", DEFAULT_MODEL).strip() or DEFAULT_MODEL
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "hola"}],
        "max_tokens": 128,
        "temperature": 0.7,
    }
    req = urllib.request.Request(
        GROQ_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
            # Sin User-Agent, Cloudflare suele responder 403 / error 1010 a urllib.
            "User-Agent": "DocVizGroqSmokeTest/1.0 (Python urllib)",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read().decode("utf-8")
            data = json.loads(body)
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code}: {err}", file=sys.stderr)
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f"Error de red: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        text = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        print("Respuesta inesperada:", json.dumps(data, indent=2))
        sys.exit(1)

    print("Modelo:", data.get("model", model))
    print("Respuesta:", text)


if __name__ == "__main__":
    main()
