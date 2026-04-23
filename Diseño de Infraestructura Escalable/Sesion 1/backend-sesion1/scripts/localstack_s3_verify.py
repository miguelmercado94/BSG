#!/usr/bin/env python3
"""
Comprueba que un objeto existe en S3 (LocalStack) y opcionalmente muestra un extracto del contenido.

  pip install -r requirements-s3-localstack.txt

Ejemplos:
  python localstack_s3_verify.py
  python localstack_s3_verify.py --list
  python localstack_s3_verify.py --key "usuario__repo/support/uuid_README.md"
  python localstack_s3_verify.py --prefix "miguellllllr3__"
"""

from __future__ import annotations

import argparse
import os
import sys

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
except ImportError:
    print("Falta boto3: pip install -r requirements-s3-localstack.txt", file=sys.stderr)
    sys.exit(1)


def s3_client(endpoint: str):
    return boto3.client(
        "s3",
        endpoint_url=endpoint.rstrip("/"),
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
        region_name=os.environ.get("AWS_DEFAULT_REGION", "us-east-1"),
        config=Config(s3={"addressing_style": "path"}),
    )


def main() -> int:
    p = argparse.ArgumentParser(description="Verificar objetos en LocalStack S3")
    p.add_argument(
        "--endpoint",
        default=os.environ.get("AWS_ENDPOINT_URL", "http://127.0.0.1:4566"),
        help="URL de LocalStack (default: http://127.0.0.1:4566)",
    )
    p.add_argument("--bucket", default="docviz-support", help="Nombre del bucket")
    p.add_argument("--key", default="", help="Clave exacta del objeto a comprobar")
    p.add_argument("--prefix", default="", help="Prefijo al listar (con --list o sin --key)")
    p.add_argument(
        "--list",
        action="store_true",
        help="Listar objetos (usa --prefix opcional)",
    )
    p.add_argument(
        "--head",
        action="store_true",
        help="Con --key, solo metadatos (sin descargar cuerpo)",
    )
    p.add_argument(
        "--preview-chars",
        type=int,
        default=500,
        help="Caracteres del texto a mostrar si es descargable (default 500)",
    )
    args = p.parse_args()

    client = s3_client(args.endpoint)

    try:
        client.head_bucket(Bucket=args.bucket)
    except ClientError as e:
        print(f"No se puede acceder al bucket {args.bucket!r}: {e}", file=sys.stderr)
        return 2

    if args.key:
        try:
            head = client.head_object(Bucket=args.bucket, Key=args.key)
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") == "404":
                print(f"NO existe: s3://{args.bucket}/{args.key}")
                return 1
            raise
        print(f"OK: existe s3://{args.bucket}/{args.key}")
        print(f"     Tamaño: {head['ContentLength']} bytes")
        print(f"     Content-Type: {head.get('ContentType', '(sin)')}")
        if args.head:
            return 0
        obj = client.get_object(Bucket=args.bucket, Key=args.key)
        body = obj["Body"].read()
        try:
            text = body.decode("utf-8")
            snippet = text[: args.preview_chars]
            if len(text) > args.preview_chars:
                snippet += "\n... [truncado]"
            print("--- contenido (preview) ---")
            print(snippet)
        except UnicodeDecodeError:
            print(f"--- binario, {len(body)} bytes (no preview texto) ---")
        return 0

    # Listar
    kwargs = {"Bucket": args.bucket}
    if args.prefix:
        kwargs["Prefix"] = args.prefix

    paginator = client.get_paginator("list_objects_v2")
    count = 0
    for page in paginator.paginate(**kwargs):
        for item in page.get("Contents", []):
            count += 1
            k = item["Key"]
            sz = item["Size"]
            print(f"  {k}  ({sz} bytes)")
    if count == 0:
        print(f"(vacío) bucket={args.bucket!r} prefix={args.prefix!r}")
        return 1 if not args.list else 0
    print(f"--- Total: {count} objeto(s) ---")
    return 0


if __name__ == "__main__":
    sys.exit(main())
