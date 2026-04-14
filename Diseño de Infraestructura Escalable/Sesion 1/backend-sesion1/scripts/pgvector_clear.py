#!/usr/bin/env python3
"""
Limpia filas en docviz_vector_chunk (pgvector), equivalente a vaciar el índice por namespace en la API.

Uso (desde backend-sesion1, con el mismo .env que Spring):
  pip install -r scripts/requirements-smoke.txt
  python scripts/pgvector_clear.py --list
  python scripts/pgvector_clear.py --namespace python_smoke_test
  python scripts/pgvector_clear.py --all --yes

Variables (mismas que el backend / pgvector_smoke_test):
  DATABASE_URL   jdbc:postgresql://localhost:5432/docviz  o  postgresql://user:pass@host:5432/docviz
  DATABASE_USER / DATABASE_PASSWORD  (si la URL JDBC no lleva credenciales)
"""
from __future__ import annotations

import argparse
import os
import sys
from urllib.parse import urlparse

import psycopg2

TABLE = "docviz_vector_chunk"


def parse_connection() -> dict:
    """Compatible con .env Spring (jdbc:postgresql + usuario aparte) y con postgresql:// del smoke test."""
    raw = os.environ.get("DATABASE_URL", "jdbc:postgresql://localhost:5432/docviz")
    user = os.environ.get("DATABASE_USER", "docviz")
    password = os.environ.get("DATABASE_PASSWORD", "docviz")

    if raw.startswith("jdbc:"):
        raw = raw[5:]
    if not raw.startswith(("postgresql://", "postgres://")):
        raw = "postgresql://" + raw.lstrip("/")

    p = urlparse(raw)
    return {
        "host": p.hostname or "localhost",
        "port": p.port or 5432,
        "dbname": (p.path or "/docviz").lstrip("/") or "docviz",
        "user": p.username or user,
        "password": p.password if p.password is not None else password,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Limpia vectores en PostgreSQL (tabla docviz_vector_chunk).")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument(
        "--list",
        action="store_true",
        help="Lista namespaces y número de filas (no borra).",
    )
    g.add_argument(
        "--namespace",
        metavar="NS",
        help="Borra solo las filas con ese namespace (como DELETE /vector/index en la app).",
    )
    g.add_argument(
        "--all",
        action="store_true",
        help="Borra todas las filas de la tabla vectorial.",
    )
    ap.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="Con --all, no pide confirmación en consola.",
    )
    args = ap.parse_args()

    cfg = parse_connection()
    conn = psycopg2.connect(**cfg)
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            if args.list:
                cur.execute(
                    f"""
                    SELECT namespace, COUNT(*)::bigint AS n
                    FROM {TABLE}
                    GROUP BY namespace
                    ORDER BY namespace
                    """
                )
                rows = cur.fetchall()
                if not rows:
                    print("(sin filas en %s)" % TABLE)
                    return 0
                w = max(len(str(ns)) for ns, _ in rows)
                for ns, n in rows:
                    print(f"{ns:{w}}  {n}")
                return 0

            if args.namespace:
                cur.execute(
                    f"DELETE FROM {TABLE} WHERE namespace = %s",
                    (args.namespace,),
                )
                deleted = cur.rowcount
                conn.commit()
                print(f"Borrado namespace={args.namespace!r}: {deleted} fila(s).")
                return 0

            # --all
            cur.execute(f"SELECT COUNT(*) FROM {TABLE}")
            total = cur.fetchone()[0]
            if total == 0:
                print("La tabla ya está vacía.")
                return 0
            if not args.yes:
                print(
                    f"Se borrarán {total} fila(s) de {TABLE}. "
                    "Vuelve a ejecutar con --yes para confirmar.",
                    file=sys.stderr,
                )
                return 3
            cur.execute(f"TRUNCATE TABLE {TABLE}")
            conn.commit()
            print(f"Tabla {TABLE} truncada ({total} fila(s) eliminadas).")
            return 0
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
