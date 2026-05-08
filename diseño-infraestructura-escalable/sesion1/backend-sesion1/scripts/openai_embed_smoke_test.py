#!/usr/bin/env python3
"""
Prueba mínima de embeddings OpenAI (misma API que usa DocViz en pdn: text-embedding-3-small).

Lee un Markdown (por defecto ENTREGABLE.md en la carpeta sesion1) y llama a POST /v1/embeddings.
No toca base de datos ni el backend Java: solo demuestra que la clave y el modelo responden.

Uso (PowerShell):
  cd backend-sesion1
  $env:OPENAI_API_KEY = "sk-..."   # no commitees la clave
  python scripts/openai_embed_smoke_test.py

Opcional — otro fichero o modelo:
  $env:OPENAI_EMBED_MODEL = "text-embedding-3-small"
  $env:OPENAI_EMBED_DIMS = "768"
  python scripts/openai_embed_smoke_test.py ..\\..\\ENTREGABLE.md
"""
from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request

OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings"
DEFAULT_MODEL = "text-embedding-3-small"
DEFAULT_DIMS = "768"
# Límite conservador; si hiciera falta, trocea como TextChunker en el backend
MAX_INPUT_CHARS = 30_000


def main() -> int:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not key:
        print(
            "Error: define OPENAI_API_KEY en el entorno (no la guardes en el repo).",
            file=sys.stderr,
        )
        return 1

    here = os.path.dirname(os.path.abspath(__file__))
    default_md = os.path.normpath(os.path.join(here, "..", "..", "ENTREGABLE.md"))
    path = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else default_md

    if not os.path.isfile(path):
        print(f"Error: no existe el fichero: {path}", file=sys.stderr)
        return 1

    with open(path, encoding="utf-8", errors="replace") as f:
        text = f.read()
    if len(text) > MAX_INPUT_CHARS:
        print(
            f"Aviso: recortando entrada de {len(text)} a {MAX_INPUT_CHARS} caracteres.\n"
        )
        text = text[:MAX_INPUT_CHARS]

    model = os.environ.get("OPENAI_EMBED_MODEL", DEFAULT_MODEL).strip() or DEFAULT_MODEL
    dims = os.environ.get("OPENAI_EMBED_DIMS", DEFAULT_DIMS).strip() or DEFAULT_DIMS
    try:
        dims_int = int(dims)
    except ValueError:
        dims_int = None

    payload = {"model": model, "input": text}
    if dims_int is not None:
        payload["dimensions"] = dims_int

    body = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        OPENAI_EMBED_URL,
        data=body,
        method="POST",
        headers={
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
    )

    print("=== OpenAI embeddings (smoke) ===")
    print(f"Archivo:     {path}")
    print(f"Caracteres:  {len(text)}")
    print(f"Modelo:      {model}")
    if dims_int is not None:
        print(f"dimensions:  {dims_int} (como application-pdn + text-embedding-3-small)")
    print()

    try:
        with urllib.request.urlopen(req, timeout=120) as res:
            raw = res.read().decode("utf-8", errors="replace")
        data = json.loads(raw)
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code} {e.reason}", file=sys.stderr)
        print(err_body, file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"Error de red: {e}", file=sys.stderr)
        return 1

    emb_data = (data.get("data") or [{}])[0]
    emb = emb_data.get("embedding")
    usage = data.get("usage", {})

    print("Respuesta OK (resumen, no vuelco el vector completo):")
    print(f"  object:          {data.get('object')}")
    print(f"  model (API):     {data.get('model')}")
    if emb is not None:
        print(f"  len(embedding):  {len(emb)}")
        head = [round(x, 6) for x in emb[:12]]
        print(f"  primeros 12:     {head}")
    else:
        print("  (sin 'embedding' en data[0])")
    print(f"  usage:           {usage}")
    print()
    print("Log completo (JSON) en una línea por si quieres copiar a otro sitio:")
    print(json.dumps(data, ensure_ascii=False)[:2000] + ("…" if len(json.dumps(data)) > 2000 else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
