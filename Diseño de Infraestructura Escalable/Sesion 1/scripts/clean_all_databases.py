#!/usr/bin/env python3
"""
Limpieza de datos locales del proyecto (Sesión 1) — «ejercicio limpio».

Incluye:
  • PostgreSQL DocViz (puerto 5432): dominio + pgvector (docviz_task, células, chunks).
  • PostgreSQL Security (puerto 5433, opcional): usuarios y tokens de recuperación
    (módulos/roles/operaciones no se tocan con --security-users: se truncan user/user_rol).
  • Firestore (opcional): colecciones users y _system.
  • LocalStack (opcional): vacía el bucket S3 de soporte DocViz y borra ítems de la tabla
    DynamoDB de tokens revocados (mismo endpoint que docker-compose: 4566).

No incluye (hazlo aparte si aplica):
  • Redis: redis-cli -h HOST FLUSHALL (solo si usas perfil qa/pdn con Redis).
  • Pinecone: python scripts/clear_pinecone_index.py
  • Volúmenes Docker por completo: docker compose down -v (borra Postgres, LocalStack, etc.)
  • Clones Git bajo context-masters: borrar carpeta en host o dentro del contenedor backend.

Variables DocViz (backend-sesion1/.env):
  DATABASE_URL, DATABASE_USER, DATABASE_PASSWORD
  DOCVIZ_SUPPORT_S3_BUCKET (default docviz-support) — usado con --localstack

Variables Security (back-security-sesion1/.env):
  SPRING_R2DBC_URL o SECURITY_PG_HOST / SECURITY_PG_PORT / …

LocalStack (--localstack):
  LOCALSTACK_ENDPOINT (default http://127.0.0.1:4566)
  AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (default test/test, como en compose)
  BSG_SECURITY_AWS_DYNAMODB_REVOKED_TOKENS_TABLE (default bsg_revoked_tokens)

Uso (desde la carpeta «Sesion 1»):
  pip install -r scripts/requirements-cleanup.txt
  python scripts/clean_all_databases.py
  python scripts/clean_all_databases.py --yes
  python scripts/clean_all_databases.py --yes --security-users
  python scripts/clean_all_databases.py --yes --firestore
  python scripts/clean_all_databases.py --yes --localstack
  python scripts/clean_all_databases.py --yes --security-users --firestore --localstack
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from urllib.parse import urlparse

# --- DocViz: orden respetando FKs (hijos → padres) ---
DOCVIZ_TRUNCATE_ORDER = (
    "docviz_task",
    "docviz_cell_repo",
    "docviz_cell",
    "docviz_vector_chunk",
)

# --- Security: solo datos operativos; conserva module, operation, role, rol_operation ---
SECURITY_TRUNCATE_ORDER = (
    "password_recovery_token",
    "user_rol",
    '"user"',  # palabra reservada
)


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


def parse_jdbc_or_pg_url(database_url: str) -> dict:
    """jdbc:postgresql://host:5432/db o postgresql://..."""
    raw = database_url.strip()
    if raw.startswith("jdbc:"):
        raw = raw[5:]
    if not raw.startswith(("postgresql://", "postgres://")):
        raw = "postgresql://" + raw.lstrip("/")
    p = urlparse(raw)
    return {
        "host": p.hostname or "localhost",
        "port": p.port or 5432,
        "dbname": (p.path or "/docviz").lstrip("/") or "docviz",
        "user": p.username or os.environ.get("DATABASE_USER", "docviz"),
        "password": p.password if p.password is not None else os.environ.get("DATABASE_PASSWORD", "docviz"),
    }


def parse_r2dbc_security(url: str) -> dict:
    """r2dbc:postgresql://host:port/db"""
    u = url.strip()
    if u.startswith("r2dbc:"):
        u = u[6:]  # postgresql://...
    if not u.startswith(("postgresql://", "postgres://")):
        u = "postgresql://" + u.lstrip("/")
    p = urlparse(u)
    return {
        "host": p.hostname or "localhost",
        "port": p.port or 5432,
        "dbname": (p.path or "/bsg_security").lstrip("/") or "bsg_security",
        "user": p.username or os.environ.get("SECURITY_PG_USER", "bsg_security"),
        "password": p.password if p.password is not None else os.environ.get("SECURITY_PG_PASSWORD", "bsg_security"),
    }


def security_connection_from_env() -> dict:
    if os.environ.get("SECURITY_PG_HOST"):
        return {
            "host": os.environ["SECURITY_PG_HOST"],
            "port": int(os.environ.get("SECURITY_PG_PORT", "5433")),
            "dbname": os.environ.get("SECURITY_PG_DB", "bsg_security"),
            "user": os.environ.get("SECURITY_PG_USER", "bsg_security"),
            "password": os.environ.get("SECURITY_PG_PASSWORD", "bsg_security"),
        }
    r2 = os.environ.get("SPRING_R2DBC_URL", "")
    if r2:
        return parse_r2dbc_security(r2)
    return {
        "host": "localhost",
        "port": 5433,
        "dbname": "bsg_security",
        "user": "bsg_security",
        "password": "bsg_security",
    }


def count_rows(cur, table: str) -> int:
    cur.execute(f"SELECT COUNT(*) FROM {table}")
    return int(cur.fetchone()[0])


def truncate_docviz(conn) -> None:
    conn.autocommit = False
    tables = ", ".join(DOCVIZ_TRUNCATE_ORDER)
    with conn.cursor() as cur:
        cur.execute(f"TRUNCATE TABLE {tables} RESTART IDENTITY CASCADE")
    conn.commit()


def truncate_security_users(conn) -> None:
    conn.autocommit = False
    with conn.cursor() as cur:
        for t in SECURITY_TRUNCATE_ORDER:
            cur.execute(f"TRUNCATE TABLE {t} RESTART IDENTITY CASCADE")
    conn.commit()


def print_docviz_counts(cfg: dict) -> None:
    import psycopg2

    conn = psycopg2.connect(**cfg)
    try:
        with conn.cursor() as cur:
            for t in DOCVIZ_TRUNCATE_ORDER:
                n = count_rows(cur, t)
                print(f"  {t}: {n} fila(s)")
    finally:
        conn.close()


def print_security_counts(cfg: dict) -> None:
    import psycopg2

    conn = psycopg2.connect(**cfg)
    try:
        with conn.cursor() as cur:
            for t in SECURITY_TRUNCATE_ORDER:
                n = count_rows(cur, t)
                print(f"  {t}: {n} fila(s)")
    finally:
        conn.close()


def clean_firestore(project_id: str, credentials_path: str) -> None:
    os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", credentials_path)
    from google.cloud import firestore

    client = firestore.Client(project=project_id)

    def wipe(name: str) -> None:
        coll = client.collection(name)
        client.recursive_delete(coll)
        print(f"Firestore: recursive_delete '{name}' OK (proyecto {project_id})")

    wipe("users")
    wipe("_system")


def clean_localstack_s3(endpoint: str, region: str, bucket: str) -> None:
    import boto3
    from botocore.exceptions import ClientError

    client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        region_name=region,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    )
    try:
        paginator = client.get_paginator("list_objects_v2")
        n = 0
        for page in paginator.paginate(Bucket=bucket):
            for obj in page.get("Contents", []):
                client.delete_object(Bucket=bucket, Key=obj["Key"])
                n += 1
        print(f"LocalStack S3: bucket '{bucket}' - eliminados {n} objeto(s) ({endpoint})")
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        if code in ("NoSuchBucket", "404"):
            print(f"LocalStack S3: bucket '{bucket}' no existe - omitido.", file=sys.stderr)
        else:
            raise


def clean_localstack_dynamodb(endpoint: str, region: str, table: str) -> None:
    """Borra todos los ítems de la tabla (PK access_token_hash o token_hash legado)."""
    import boto3
    from botocore.exceptions import ClientError

    dynamo = boto3.resource(
        "dynamodb",
        endpoint_url=endpoint,
        region_name=region,
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    )
    tbl = dynamo.Table(table)
    try:
        tbl.load()
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code", "")
        err_msg = str(e).lower()
        if code == "ResourceNotFoundException":
            print(f"LocalStack DynamoDB: tabla '{table}' no existe - omitido.", file=sys.stderr)
            return
        if code == "InternalFailure" or "not enabled" in err_msg:
            print(
                "LocalStack DynamoDB: servicio DynamoDB no activo en este LocalStack - omitido.",
                file=sys.stderr,
            )
            return
        raise

    deleted = 0
    scan_kwargs: dict = {}
    while True:
        resp = tbl.scan(**scan_kwargs)
        items = resp.get("Items", [])
        with tbl.batch_writer() as batch:
            for it in items:
                if "access_token_hash" in it:
                    batch.delete_item(Key={"access_token_hash": it["access_token_hash"]})
                    deleted += 1
                elif "token_hash" in it:
                    batch.delete_item(Key={"token_hash": it["token_hash"]})
                    deleted += 1
        lek = resp.get("LastEvaluatedKey")
        if not lek:
            break
        scan_kwargs = {"ExclusiveStartKey": lek}
    print(f"LocalStack DynamoDB: tabla '{table}' - eliminados {deleted} item(s) ({endpoint})")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Vacía tablas DocViz y, opcionalmente, usuarios en Security y Firestore."
    )
    parser.add_argument(
        "-y",
        "--yes",
        action="store_true",
        help="Confirmación obligatoria para ejecutar borrados.",
    )
    parser.add_argument(
        "--security-users",
        action="store_true",
        help="También vacía tablas de usuario en PostgreSQL Security (puerto 5433 típico).",
    )
    parser.add_argument(
        "--firestore",
        action="store_true",
        help="También borra colecciones users y _system en Firestore (requiere credenciales).",
    )
    parser.add_argument(
        "--localstack",
        action="store_true",
        help="También vacía S3 (markdown soporte) y DynamoDB (tokens revocados) en LocalStack.",
    )
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    sesion1 = script_dir.parent

    load_dotenv(sesion1 / "backend-sesion1" / ".env")
    load_dotenv(sesion1 / "back-security-sesion1" / ".env")

    database_url = os.environ.get("DATABASE_URL", "jdbc:postgresql://localhost:5432/docviz")
    docviz_cfg = parse_jdbc_or_pg_url(database_url)

    print("=== DocViz (PostgreSQL) ===")
    print(f"Conexión: {docviz_cfg['host']}:{docviz_cfg['port']}/{docviz_cfg['dbname']}")
    try:
        print_docviz_counts(docviz_cfg)
    except Exception as e:
        print(f"  (no se pudo leer: {e})", file=sys.stderr)

    if args.security_users:
        sec_cfg = security_connection_from_env()
        print("\n=== Security — tablas de usuario ===")
        print(f"Conexión: {sec_cfg['host']}:{sec_cfg['port']}/{sec_cfg['dbname']}")
        try:
            print_security_counts(sec_cfg)
        except Exception as e:
            print(f"  (no se pudo leer: {e})", file=sys.stderr)

    if not args.yes:
        print(
            "\nNo se ha borrado nada. Ejecuta con --yes para truncar DocViz "
            "(y --security-users / --firestore / --localstack si aplica)."
        )
        return 0

    import psycopg2

    print("\n--- Ejecutando ---")
    try:
        conn = psycopg2.connect(**docviz_cfg)
        try:
            truncate_docviz(conn)
            print("DocViz: TRUNCATE OK ->", ", ".join(DOCVIZ_TRUNCATE_ORDER))
        finally:
            conn.close()
    except Exception as e:
        print(f"DocViz: error: {e}", file=sys.stderr)
        return 1

    if args.security_users:
        sec_cfg = security_connection_from_env()
        try:
            conn = psycopg2.connect(**sec_cfg)
            try:
                truncate_security_users(conn)
                print("Security (usuarios): TRUNCATE OK ->", ", ".join(SECURITY_TRUNCATE_ORDER))
            finally:
                conn.close()
        except Exception as e:
            print(f"Security: error: {e}", file=sys.stderr)
            return 1

    if args.firestore:
        project_id = os.environ.get("FIREBASE_PROJECT_ID", "sesion-bsg")
        cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH") or os.environ.get(
            "GOOGLE_APPLICATION_CREDENTIALS", ""
        )
        if not cred_path or not Path(cred_path).is_file():
            print("Firestore: sin credenciales — omitido.", file=sys.stderr)
            return 1
        try:
            clean_firestore(project_id, cred_path)
        except Exception as e:
            print(f"Firestore: error: {e}", file=sys.stderr)
            return 1

    if args.localstack:
        endpoint = os.environ.get("LOCALSTACK_ENDPOINT", "http://127.0.0.1:4566")
        region = os.environ.get("AWS_DEFAULT_REGION", os.environ.get("DOCVIZ_SUPPORT_S3_REGION", "us-east-1"))
        bucket = os.environ.get("DOCVIZ_SUPPORT_S3_BUCKET", "docviz-support")
        table = os.environ.get("BSG_SECURITY_AWS_DYNAMODB_REVOKED_TOKENS_TABLE", "bsg_revoked_tokens")
        try:
            clean_localstack_s3(endpoint, region, bucket)
        except Exception as e:
            print(f"LocalStack S3: error: {e}", file=sys.stderr)
            return 1
        try:
            clean_localstack_dynamodb(endpoint, region, table)
        except Exception as e:
            print(f"LocalStack DynamoDB: error: {e}", file=sys.stderr)
            return 1

    print("\nListo.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
