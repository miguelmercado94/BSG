"""
Prueba rápida de OPENAI_API_KEY (lee env o backend-sesion1/.env).
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

SESSION_ROOT = Path(__file__).resolve().parent.parent
BACKEND_ENV = SESSION_ROOT / "backend-sesion1" / ".env"


def load_dotenv(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if m:
            k, v = m.group(1), m.group(2).strip().strip('"').strip("'")
            out[k] = v
    return out


def main() -> int:
    env_file = load_dotenv(BACKEND_ENV)
    api_key = os.environ.get("OPENAI_API_KEY") or env_file.get("OPENAI_API_KEY", "")
    model = os.environ.get("OPENAI_CHAT_MODEL") or env_file.get("OPENAI_CHAT_MODEL", "gpt-4o-mini")

    if not api_key:
        print("Falta OPENAI_API_KEY", file=sys.stderr)
        return 1

    try:
        from openai import OpenAI
    except ImportError:
        print("Instala: pip install openai", file=sys.stderr)
        return 1

    client = OpenAI(api_key=api_key)
    try:
        r = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": 'Responde solo la palabra "ok" en minúsculas.'}],
            max_tokens=16,
        )
    except Exception as e:
        err = str(e)
        if "insufficient_quota" in err or "429" in err:
            print("La clave es válida (OpenAI aceptó la petición), pero la cuenta no tiene cuota/billing activo (429).")
            print("Revisa facturación en https://platform.openai.com/account/billing")
            return 2
        raise
    text = (r.choices[0].message.content or "").strip()
    print(f"Modelo: {model}")
    print(f"Respuesta: {text}")
    print("Conexión OpenAI OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
