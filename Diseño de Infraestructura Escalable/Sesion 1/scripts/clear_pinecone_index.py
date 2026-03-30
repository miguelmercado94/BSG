"""
Vacía todos los vectores del índice Pinecone (cada namespace).
Lee PINECONE_API_KEY del entorno o de backend-sesion1/.env (no subas claves al repo).
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

# Raíz: .../Sesion 1/scripts -> padre = Sesion 1
SESSION_ROOT = Path(__file__).resolve().parent.parent
BACKEND_ENV = SESSION_ROOT / "backend-sesion1" / ".env"
DEFAULT_INDEX = "docviz-embed"


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
    api_key = os.environ.get("PINECONE_API_KEY") or env_file.get("PINECONE_API_KEY", "")
    index_name = os.environ.get("PINECONE_INDEX_NAME") or env_file.get("PINECONE_INDEX_NAME", DEFAULT_INDEX)

    if not api_key:
        print("Falta PINECONE_API_KEY (variable de entorno o backend-sesion1/.env)", file=sys.stderr)
        return 1

    try:
        from pinecone import Pinecone
    except ImportError:
        print("Instala: pip install pinecone-client", file=sys.stderr)
        return 1

    pc = Pinecone(api_key=api_key)
    index = pc.Index(index_name)
    stats = index.describe_index_stats()
    namespaces = list(stats.namespaces.keys()) if stats.namespaces else []
    total = stats.total_vector_count or 0

    if total == 0 and not namespaces:
        print(f"Índice '{index_name}': ya estaba vacío.")
        return 0

    if not namespaces and total > 0:
        namespaces = [""]

    print(f"Índice '{index_name}': ~{total} vectores en {len(namespaces)} namespace(s).")
    for ns in namespaces:
        count = stats.namespaces[ns].vector_count if stats.namespaces and ns in stats.namespaces else 0
        label = repr(ns) if ns != "" else "'' (default)"
        print(f"  Borrando namespace {label} (~{count} vectores)...")
        index.delete(delete_all=True, namespace=ns)

    print("Listo: índice limpiado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
