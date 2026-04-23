#!/usr/bin/env python3
"""
Lista claves en S3 vía LocalStack. DocViz usa tres buckets: soporte, borradores, workarea.

  pip install boto3>=1.34
  # o: pip install -r ../backend-sesion1/scripts/requirements-s3-localstack.txt

Ejemplos:
  python list_localstack_s3_paths.py --docviz
  python list_localstack_s3_paths.py --bucket soporte
  python list_localstack_s3_paths.py --json
  python list_localstack_s3_paths.py --all-buckets
"""

from __future__ import annotations

import argparse
import json
import os
import sys

try:
    import boto3
    from botocore.config import Config
    from botocore.exceptions import ClientError
except ImportError:
    print("Falta boto3: pip install boto3>=1.34", file=sys.stderr)
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


def list_keys(client, bucket: str, prefix: str) -> list[dict]:
    out: list[dict] = []
    paginator = client.get_paginator("list_objects_v2")
    kwargs: dict = {"Bucket": bucket}
    if prefix:
        kwargs["Prefix"] = prefix
    for page in paginator.paginate(**kwargs):
        for item in page.get("Contents", []):
            key = item["Key"]
            out.append(
                {
                    "key": key,
                    "s3_uri": f"s3://{bucket}/{key}",
                    "size": item["Size"],
                    "last_modified": item["LastModified"].isoformat()
                    if item.get("LastModified")
                    else None,
                }
            )
    return out


def main() -> int:
    p = argparse.ArgumentParser(description="Listar paths de objetos en LocalStack S3")
    p.add_argument(
        "--endpoint",
        default=os.environ.get("AWS_ENDPOINT_URL", "http://127.0.0.1:4566"),
        help="LocalStack (desde el host: http://127.0.0.1:4566)",
    )
    p.add_argument(
        "--bucket",
        default=os.environ.get("DOCVIZ_SUPPORT_S3_BUCKET", "soporte"),
        help="Un solo bucket (p. ej. soporte)",
    )
    p.add_argument(
        "--docviz",
        action="store_true",
        help="Listar soporte + borradores + workarea (tres buckets DocViz)",
    )
    p.add_argument("--prefix", default="", help="Filtrar por prefijo de clave")
    p.add_argument(
        "--json",
        action="store_true",
        help="Salida JSON (lista de objetos con key, s3_uri, size, last_modified)",
    )
    p.add_argument(
        "--keys-only",
        action="store_true",
        help="Una clave por línea (sin JSON ni tamaño)",
    )
    p.add_argument(
        "--all-buckets",
        action="store_true",
        help="Listar todos los buckets y en cada uno sus objetos",
    )
    args = p.parse_args()
    client = s3_client(args.endpoint)

    docviz_buckets = ("soporte", "borradores", "workarea")
    if args.docviz:
        all_data: list[dict] = []
        for b in docviz_buckets:
            try:
                client.head_bucket(Bucket=b)
            except ClientError:
                continue
            for row in list_keys(client, b, args.prefix):
                row["bucket"] = b
                all_data.append(row)
        if args.json:
            print(json.dumps(all_data, indent=2, ensure_ascii=False))
        elif args.keys_only:
            for row in all_data:
                print(f"{row['bucket']}/{row['key']}")
        else:
            for row in all_data:
                print(f"[{row['bucket']}] {row['key']}  ({row['size']} bytes)")
        print(f"--- Total: {len(all_data)} objeto(s) en buckets DocViz ---")
        return 0

    if args.all_buckets:
        try:
            resp = client.list_buckets()
        except ClientError as e:
            print(f"Error listando buckets: {e}", file=sys.stderr)
            return 2
        buckets = [b["Name"] for b in resp.get("Buckets", [])]
        all_data: list[dict] = []
        for b in buckets:
            for row in list_keys(client, b, args.prefix):
                row["bucket"] = b
                all_data.append(row)
        if args.json:
            print(json.dumps(all_data, indent=2, ensure_ascii=False))
        elif args.keys_only:
            for row in all_data:
                print(row["key"])
        else:
            for row in all_data:
                print(f"{row['s3_uri']}  ({row['size']} bytes)")
        print(f"--- Total: {len(all_data)} objeto(s) en {len(buckets)} bucket(s) ---")
        return 0

    try:
        client.head_bucket(Bucket=args.bucket)
    except ClientError as e:
        print(
            f"No se puede acceder al bucket {args.bucket!r}: {e}",
            file=sys.stderr,
        )
        return 2

    rows = list_keys(client, args.bucket, args.prefix)
    if args.json:
        print(json.dumps(rows, indent=2, ensure_ascii=False))
    elif args.keys_only:
        for row in rows:
            print(row["key"])
    else:
        for row in rows:
            print(f"{row['key']}")
            print(f"  → {row['s3_uri']}  ({row['size']} bytes)")
    print(f"--- Total: {len(rows)} objeto(s) ---")
    return 0


if __name__ == "__main__":
    sys.exit(main())
