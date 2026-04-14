#!/usr/bin/env python3
"""
Comprueba conexión a PostgreSQL, extensión pgvector y tabla docviz_vector_chunk
(compatible con com.bsg.docviz.vector.PgVectorStore).

Uso (desde la carpeta scripts):
  pip install -r requirements-pg-test.txt
  python check_pgvector.py

Variables opcionales: PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD PG_VECTOR_DIM
Por defecto: localhost:5432, db docviz, user/pass docviz, dimensión 768.
"""

from __future__ import annotations

import os
import sys


def main() -> int:
    try:
        import psycopg
        from pgvector.psycopg import register_vector
    except ImportError as e:
        print("Falta dependencia:", e, file=sys.stderr)
        print('Ejecuta: pip install -r requirements-pg-test.txt', file=sys.stderr)
        return 1

    host = os.environ.get("PGHOST", "127.0.0.1")
    port = os.environ.get("PGPORT", "5432")
    db = os.environ.get("PGDATABASE", "docviz")
    user = os.environ.get("PGUSER", "docviz")
    password = os.environ.get("PGPASSWORD", "docviz")
    dim = int(os.environ.get("PG_VECTOR_DIM", "768"))

    conninfo = (
        f"host={host} port={port} dbname={db} user={user} password={password}"
    )

    print(f"Conectando a PostgreSQL {host}:{port}/{db} (usuario {user})...")

    try:
        with psycopg.connect(conninfo, connect_timeout=10) as conn:
            register_vector(conn)
            with conn.cursor() as cur:
                cur.execute("SELECT version()")
                (ver,) = cur.fetchone()
                print("OK - PostgreSQL:", ver.split(",")[0])

                cur.execute(
                    "SELECT extname, extversion FROM pg_extension WHERE extname = 'vector'"
                )
                row = cur.fetchone()
                if not row:
                    print(
                        "ADVERTENCIA: extension 'vector' no instalada. "
                        "El backend la crea con CREATE EXTENSION al arrancar."
                    )
                else:
                    print(f"OK - extension pgvector: {row[0]} {row[1]}")

                cur.execute(
                    """
                    SELECT EXISTS (
                      SELECT FROM information_schema.tables
                      WHERE table_schema = 'public'
                        AND table_name = 'docviz_vector_chunk'
                    )
                    """
                )
                (exists,) = cur.fetchone()
                if not exists:
                    print(
                        "INFO: tabla docviz_vector_chunk aun no existe "
                        "(normal si no has arrancado el backend con pgvector)."
                    )
                else:
                    cur.execute(
                        "SELECT COUNT(*) FROM docviz_vector_chunk"
                    )
                    (n,) = cur.fetchone()
                    print(f"OK - tabla docviz_vector_chunk: {n} filas")

                    cur.execute(
                        """
                        SELECT column_name, data_type, udt_name
                        FROM information_schema.columns
                        WHERE table_name = 'docviz_vector_chunk'
                        ORDER BY ordinal_position
                        """
                    )
                    print("Columnas:")
                    for col in cur.fetchall():
                        print(f"  - {col[0]}: {col[1]} ({col[2]})")

                # Prueba mínima de vector (insert + distancia coseno).
                # La dimensión debe ir literal en el DDL (no como parámetro preparado).
                cur.execute(
                    f"CREATE TEMP TABLE IF NOT EXISTS _docviz_py_test ("
                    f"id serial PRIMARY KEY, embedding vector({dim}))"
                )
                vec = [0.01] * dim
                vec[0] = 1.0
                cur.execute(
                    "INSERT INTO _docviz_py_test (embedding) VALUES (%s::vector)",
                    (vec,),
                )
                cur.execute(
                    "SELECT embedding <=> %s::vector AS dist FROM _docviz_py_test LIMIT 1",
                    (vec,),
                )
                (dist,) = cur.fetchone()
                print(
                    f"OK - prueba vector({dim}): distancia a si mismo = {float(dist):.6f} (esperado casi 0)"
                )

            conn.commit()
    except Exception as e:
        print("ERROR:", e, file=sys.stderr)
        return 2

    print("\nBase de datos y pgvector: OK.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
