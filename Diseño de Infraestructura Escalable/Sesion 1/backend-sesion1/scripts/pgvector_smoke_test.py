#!/usr/bin/env python3
"""
Prueba mínima: texto → chunks → embeddings (Ollama HTTP) → INSERT en docviz_vector_chunk (pgvector).

Uso (desde la carpeta backend-sesion1 o scripts):
  pip install -r scripts/requirements-smoke.txt
  python scripts/pgvector_smoke_test.py

Variables (opcional, por defecto igual que .env local):
  DATABASE_URL  postgresql://docviz:docviz@localhost:5432/docviz
  OLLAMA_BASE_URL   http://127.0.0.1:11434
  OLLAMA_EMBED_MODEL  nomic-embed-text
  EMBED_DIM   768   (debe coincidir con la columna vector(dim) y el modelo)
"""
from __future__ import annotations

import json
import os
import sys
import uuid
from urllib.parse import urlparse

import psycopg2
import requests


def chunk_text(text: str, size: int = 400, overlap: int = 50) -> list[str]:
    text = text.strip()
    if not text:
        return []
    chunks: list[str] = []
    i = 0
    while i < len(text):
        chunks.append(text[i : i + size])
        i += max(1, size - overlap)
    return chunks


def ollama_embed(base_url: str, model: str, prompt: str, timeout: float = 120.0) -> list[float]:
    url = base_url.rstrip("/") + "/api/embeddings"
    # API clásica Ollama
    body = {"model": model, "prompt": prompt}
    r = requests.post(url, json=body, timeout=timeout)
    if r.status_code != 200:
        # Algunas versiones usan "input"
        r2 = requests.post(
            url,
            json={"model": model, "input": prompt},
            timeout=timeout,
        )
        if r2.status_code != 200:
            raise RuntimeError(
                f"Ollama embeddings falló: {r.status_code} {r.text[:500]} | fallback {r2.status_code} {r2.text[:500]}"
            )
        data = r2.json()
    else:
        data = r.json()
    emb = data.get("embedding")
    if emb is None:
        raise RuntimeError(f"Respuesta Ollama sin 'embedding': {json.dumps(data)[:800]}")
    return [float(x) for x in emb]


def parse_database_url(url: str) -> dict:
    p = urlparse(url)
    if p.scheme not in ("postgresql", "postgres"):
        raise ValueError("DATABASE_URL debe ser postgresql://...")
    return {
        "host": p.hostname or "localhost",
        "port": p.port or 5432,
        "dbname": (p.path or "/docviz").lstrip("/") or "docviz",
        "user": p.username or "docviz",
        "password": p.password or "",
    }


def main() -> int:
    ollama = os.environ.get("OLLAMA_BASE_URL", "http://127.0.0.1:11434")
    model = os.environ.get("OLLAMA_EMBED_MODEL", "nomic-embed-text")
    dim = int(os.environ.get("DOCVIZ_VECTOR_EMBEDDING_DIM", os.environ.get("EMBED_DIM", "768")))
    db_url = os.environ.get(
        "DATABASE_URL",
        "postgresql://docviz:docviz@localhost:5432/docviz",
    )

    sample = os.environ.get(
        "SMOKE_TEXT",
        "DocViz smoke test. " * 80 + "Fin del texto de prueba para pgvector.",
    )

    namespace = os.environ.get("SMOKE_NAMESPACE", "python_smoke_test")
    user_label = os.environ.get("SMOKE_USER", "smoke_user")
    source = os.environ.get("SMOKE_SOURCE", "scripts/pgvector_smoke_test.py")

    print("1) Chunking...")
    parts = chunk_text(sample, size=400, overlap=50)
    print(f"   chunks: {len(parts)}")

    print("2) Embeddings Ollama...")
    vectors: list[list[float]] = []
    for i, t in enumerate(parts):
        v = ollama_embed(ollama, model, t)
        if len(v) != dim:
            print(
                f"   ERROR: dimensión {len(v)} != EMBED_DIM={dim}. Ajusta DOCVIZ_VECTOR_EMBEDDING_DIM o el modelo.",
                file=sys.stderr,
            )
            return 2
        vectors.append(v)
        print(f"   chunk {i + 1}/{len(parts)} OK (dim={len(v)})")

    print("3) Conectando PostgreSQL...")
    cfg = parse_database_url(db_url)
    conn = psycopg2.connect(**cfg)
    conn.autocommit = False
    try:
        with conn.cursor() as cur:
            cur.execute("CREATE EXTENSION IF NOT EXISTS vector")
            cur.execute(
                f"""
                CREATE TABLE IF NOT EXISTS docviz_vector_chunk (
                    id VARCHAR(128) PRIMARY KEY,
                    namespace VARCHAR(512) NOT NULL,
                    user_label VARCHAR(256) NOT NULL,
                    source TEXT NOT NULL,
                    chunk_index INT NOT NULL,
                    embedding vector({dim}) NOT NULL
                )
                """
            )
            conn.commit()
        print("4) Insertando filas...")
        with conn.cursor() as cur:
            for i, (text_chunk, vec) in enumerate(zip(parts, vectors)):
                rid = str(uuid.uuid4())
                vec_literal = "[" + ",".join(str(x) for x in vec) + "]"
                cur.execute(
                    """
                    INSERT INTO docviz_vector_chunk (id, namespace, user_label, source, chunk_index, embedding)
                    VALUES (%s, %s, %s, %s, %s, %s::vector)
                    ON CONFLICT (id) DO UPDATE SET
                      namespace = EXCLUDED.namespace,
                      user_label = EXCLUDED.user_label,
                      source = EXCLUDED.source,
                      chunk_index = EXCLUDED.chunk_index,
                      embedding = EXCLUDED.embedding
                    """,
                    (rid, namespace, user_label, source, i, vec_literal),
                )
        conn.commit()
        print("5) Verificando...")
        with conn.cursor() as cur:
            cur.execute(
                "SELECT COUNT(*) FROM docviz_vector_chunk WHERE namespace = %s",
                (namespace,),
            )
            n = cur.fetchone()[0]
            cur.execute(
                """
                SELECT id, chunk_index, left(source, 40)
                FROM docviz_vector_chunk
                WHERE namespace = %s
                ORDER BY chunk_index
                LIMIT 5
                """,
                (namespace,),
            )
            rows = cur.fetchall()
        print(f"   Filas con namespace={namespace!r}: {n}")
        for row in rows:
            print(f"   sample row: {row}")
    finally:
        conn.close()

    print("Listo. Si ves filas > 0, pgvector recibió los vectores.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
