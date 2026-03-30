"""
Prueba Pinecone igual que el backend Java: POST /embed (api.pinecone.io) y POST /vectors/upsert (host del índice).

Uso (desde la carpeta Sesion 1 o con PYTHONPATH):
  python scripts/test_pinecone_backend_flow.py

Lee PINECONE_API_KEY de entorno o backend-sesion1/.env; host del índice y modelo desde
backend-sesion1/src/main/resources/application.properties (mismas claves que Spring).

Después puedes vaciar el índice con: python scripts/clear_pinecone_index.py
"""
from __future__ import annotations

import json
import os
import re
import sys
import uuid
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

SESSION_ROOT = Path(__file__).resolve().parent.parent
BACKEND_ENV = SESSION_ROOT / "backend-sesion1" / ".env"
APP_PROPS = SESSION_ROOT / "backend-sesion1" / "src" / "main" / "resources" / "application.properties"
SAMPLE_FILE = SESSION_ROOT / "docker-compose.yml"

API_VERSION = "2025-10"
DEFAULT_INFERENCE_HOST = "api.pinecone.io"
DEFAULT_MODEL = "llama-text-embed-v2"


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


def load_properties(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, _, v = line.partition("=")
            out[k.strip()] = v.strip()
    return out


def normalize_host(host: str) -> str:
    h = (host or "").strip()
    if h.startswith("https://"):
        return h[len("https://") :]
    if h.startswith("http://"):
        return h[len("http://") :]
    return h


def pinecone_embed(
    api_key: str,
    inference_host: str,
    model: str,
    texts: list[str],
    input_type: str = "passage",
) -> list[list[float]]:
    """Misma petición que PineconeVectorClient.embedTexts en Java."""
    url = f"https://{normalize_host(inference_host)}/embed"
    body = {
        "model": model,
        "parameters": {"input_type": input_type, "truncate": "END"},
        "inputs": [{"text": t} for t in texts],
    }
    data = json.dumps(body).encode("utf-8")
    req = Request(
        url,
        data=data,
        method="POST",
        headers={
            "Api-Key": api_key,
            "Content-Type": "application/json",
            "X-Pinecone-Api-Version": API_VERSION,
        },
    )
    with urlopen(req, timeout=120) as resp:
        raw = resp.read().decode("utf-8")
    root = json.loads(raw)
    out: list[list[float]] = []
    for item in root.get("data") or []:
        vals = item.get("values")
        if isinstance(vals, list) and vals:
            out.append([float(x) for x in vals])
    if not out and root.get("embeddings"):
        for emb in root["embeddings"]:
            out.append([float(x) for x in emb])
    if len(out) != len(texts):
        raise RuntimeError(f"Embed: esperaba {len(texts)} vectores, obtuve {len(out)}. Cuerpo: {raw[:500]}")
    return out


def pinecone_upsert(
    api_key: str,
    index_host: str,
    namespace: str,
    vector_id: str,
    values: list[float],
    source: str,
    chunk_index: int,
    user_label: str,
) -> None:
    """Misma petición que PineconeVectorClient.upsertBatch (un solo vector)."""
    host = normalize_host(index_host)
    url = f"https://{host}/vectors/upsert"
    body = {
        "namespace": namespace,
        "vectors": [
            {
                "id": vector_id,
                "values": values,
                "metadata": {
                    "source": source,
                    "chunkIndex": chunk_index,
                    "userLabel": user_label,
                },
            }
        ],
    }
    data = json.dumps(body).encode("utf-8")
    req = Request(
        url,
        data=data,
        method="POST",
        headers={
            "Api-Key": api_key,
            "Content-Type": "application/json",
            "X-Pinecone-Api-Version": API_VERSION,
        },
    )
    with urlopen(req, timeout=120) as resp:
        resp.read()


def main() -> int:
    env_file = load_dotenv(BACKEND_ENV)
    props = load_properties(APP_PROPS)

    api_key = (
        os.environ.get("PINECONE_API_KEY")
        or env_file.get("PINECONE_API_KEY", "")
        or props.get("docviz.vector.pinecone-api-key", "")
    ).strip()
    index_host = (
        os.environ.get("PINECONE_INDEX_HOST")
        or props.get("docviz.vector.pinecone-index-host", "")
    ).strip()
    inference_host = (
        os.environ.get("PINECONE_INFERENCE_HOST")
        or props.get("docviz.vector.pinecone-inference-host", DEFAULT_INFERENCE_HOST)
    ).strip()
    model = (
        os.environ.get("PINECONE_EMBED_MODEL")
        or props.get("docviz.vector.pinecone-embed-model", DEFAULT_MODEL)
    ).strip()

    if not api_key:
        print("Falta PINECONE_API_KEY (entorno, backend-sesion1/.env o application.properties).", file=sys.stderr)
        return 1
    if not index_host:
        print("Falta host del índice (docviz.vector.pinecone-index-host en application.properties).", file=sys.stderr)
        return 1

    if not SAMPLE_FILE.is_file():
        print(f"No existe el archivo de muestra: {SAMPLE_FILE}", file=sys.stderr)
        return 1

    text = SAMPLE_FILE.read_text(encoding="utf-8")
    display_source = "Sesion 1/docker-compose.yml"
    namespace = "python_smoke_test"
    user_label = "python-test"
    vid = f"{namespace}:{uuid.uuid4()}"

    print("1) Embed (api.pinecone.io, input_type=passage) como el backend...")
    try:
        vectors = pinecone_embed(api_key, inference_host, model, [text])
    except HTTPError as e:
        err = e.read().decode("utf-8", errors="replace") if e.fp else ""
        print(f"Embed HTTP {e.code}: {err}", file=sys.stderr)
        return 1
    except URLError as e:
        print(f"Embed red: {e}", file=sys.stderr)
        return 1

    print(f"   -> vector dim = {len(vectors[0])}")

    print("2) Upsert (host del indice /vectors/upsert) como el backend...")
    try:
        pinecone_upsert(
            api_key,
            index_host,
            namespace,
            vid,
            vectors[0],
            display_source,
            0,
            user_label,
        )
    except HTTPError as e:
        err = e.read().decode("utf-8", errors="replace") if e.fp else ""
        print(f"Upsert HTTP {e.code}: {err}", file=sys.stderr)
        return 1
    except URLError as e:
        print(f"Upsert red: {e}", file=sys.stderr)
        return 1

    print(f"   -> id={vid}")
    print(f"   -> namespace={namespace!r}, source={display_source!r}")
    print()
    print("OK: un vector insertado. Para vaciar el indice (todos los namespaces):")
    print("   python scripts/clear_pinecone_index.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
