#!/usr/bin/env python3
"""
Limpia datos de desarrollo DocViz:
  - PostgreSQL: tabla docviz_vector_chunk (vectores pgvector)
  - Firestore: colecciones users (chat) y _system (health ping)

Uso (desde la carpeta Sesion 1):
  pip install -r scripts/requirements-cleanup.txt
  python scripts/cleanup_dev_data.py
  python scripts/cleanup_dev_data.py --clean-artifacts   # además borra target/, dist/, .vite/, __pycache__/

Variables: carga backend-sesion1/.env si existe (mismas que el backend).
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path


def load_dotenv(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = val


def truncate_postgres(database_url: str, user: str, password: str) -> None:
    import psycopg2

    # jdbc:postgresql://host:5432/dbname -> host, dbname
    url = database_url.replace("jdbc:postgresql://", "postgresql://")
    if url.startswith("postgresql://"):
        rest = url[len("postgresql://") :]
        if "/" in rest:
            host_port, db = rest.split("/", 1)
            db = db.split("?")[0]
        else:
            raise ValueError("DATABASE_URL inválida")
        if ":" in host_port:
            host, port_s = host_port.rsplit(":", 1)
            port = int(port_s)
        else:
            host, port = host_port, 5432
    else:
        raise ValueError("Esperaba jdbc:postgresql:// o postgresql://")

    conn = psycopg2.connect(host=host, port=port, dbname=db, user=user, password=password)
    try:
        conn.autocommit = True
        cur = conn.cursor()
        cur.execute("TRUNCATE TABLE docviz_vector_chunk RESTART IDENTITY CASCADE")
        print(f"PostgreSQL: TRUNCATE docviz_vector_chunk OK ({host}:{port}/{db})")
    finally:
        conn.close()


def clean_firestore(project_id: str, credentials_path: str) -> None:
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", credentials_path)
    from google.cloud import firestore

    client = firestore.Client(project=project_id)

    def wipe(name: str) -> None:
        coll = client.collection(name)
        try:
            client.recursive_delete(coll)
            print(f"Firestore: recursive_delete '{name}' OK (proyecto {project_id})")
        except Exception as e:
            print(f"Firestore: error borrando '{name}': {e}", file=sys.stderr)
            raise

    wipe("users")
    wipe("_system")


def clean_artifacts(diseno_root: Path) -> None:
    skip_parts = {"node_modules", ".git", ".venv", "venv"}
    removed: list[str] = []
    for dirname in ("target", "dist", ".vite", "__pycache__"):
        for p in diseno_root.glob(f"**/{dirname}"):
            if not p.is_dir() or p.name != dirname:
                continue
            if any(x in p.parts for x in skip_parts):
                continue
            shutil.rmtree(p, ignore_errors=True)
            removed.append(str(p))
    for p in diseno_root.rglob("*.pyc"):
        if any(x in p.parts for x in skip_parts):
            continue
        try:
            p.unlink()
            removed.append(str(p))
        except OSError:
            pass
    print(f"Artefactos: eliminados {len(removed)} elementos bajo {diseno_root}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Limpia PostgreSQL + Firestore DocViz")
    parser.add_argument(
        "--clean-artifacts",
        action="store_true",
        help="Elimina target/, dist/, .vite/, __pycache__/ y *.pyc bajo Diseño de Infraestructura Escalable",
    )
    parser.add_argument("--skip-pg", action="store_true", help="No tocar PostgreSQL")
    parser.add_argument("--skip-fs", action="store_true", help="No tocar Firestore")
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    sesion1 = script_dir.parent
    backend_env = sesion1 / "backend-sesion1" / ".env"
    diseno_root = sesion1.parent

    load_dotenv(backend_env)

    database_url = os.environ.get("DATABASE_URL", "jdbc:postgresql://localhost:5432/docviz")
    db_user = os.environ.get("DATABASE_USER", "docviz")
    db_pass = os.environ.get("DATABASE_PASSWORD", "docviz")
    project_id = os.environ.get("FIREBASE_PROJECT_ID", "sesion-bsg")
    cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH") or os.environ.get(
        "GOOGLE_APPLICATION_CREDENTIALS", ""
    )

    if not args.skip_pg:
        try:
            truncate_postgres(database_url, db_user, db_pass)
        except Exception as e:
            print(f"PostgreSQL: omitido o error ({e})", file=sys.stderr)

    if not args.skip_fs:
        if not cred_path or not Path(cred_path).is_file():
            print(
                "Firestore: sin FIREBASE_CREDENTIALS_PATH / archivo inexistente — omitido.",
                file=sys.stderr,
            )
        else:
            try:
                clean_firestore(project_id, cred_path)
            except Exception as e:
                print(f"Firestore: error ({e})", file=sys.stderr)

    if args.clean_artifacts:
        clean_artifacts(diseno_root)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
