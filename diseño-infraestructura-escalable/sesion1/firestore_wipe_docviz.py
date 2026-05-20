"""
Vacía Firestore (base <default>) de todo el contenido de aplicación DocViz y pruebas.

IMPORTANTE: En Firestore, borrar solo el documento users/{id} NO borra subcolecciones
(conversations, messages). Por eso este script usa:
  - list_documents() — incluye documentos "vacíos" que solo tienen subcolecciones
  - recursive_delete() — borra el árbol completo bajo cada documento raíz

Por defecto recorre TODAS las colecciones de nivel superior (users, _system,
_connection_test, etc.) y elimina cada documento raíz con todo lo que cuelga.

  pip install -r requirements-firestore-test.txt
  python firestore_wipe_docviz.py                  # dry-run: cuenta raíces por colección
  python firestore_wipe_docviz.py --execute --yes  # borra todo (sin preguntar)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def init_firestore(credentials: Path):
    try:
        import firebase_admin
        from firebase_admin import credentials as fb_cred, firestore
    except ImportError:
        print("Instala: pip install -r requirements-firestore-test.txt", file=sys.stderr)
        sys.exit(3)

    cred = fb_cred.Certificate(str(credentials))
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)
    return firestore.client()


def wipe_all_collections(db, *, execute: bool) -> list[tuple[str, int]]:
    """
    Para cada colección raíz, lista todos los documentos (incl. padres sin campos)
    y hace recursive_delete en cada uno. Devuelve [(nombre_colección, docs_borrados), ...].
    """
    summary: list[tuple[str, int]] = []

    for coll_ref in db.collections():
        coll_name = coll_ref.id
        n = 0
        for doc_ref in coll_ref.list_documents():
            n += 1
            if execute:
                db.recursive_delete(doc_ref)
        summary.append((coll_name, n))

    return summary


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Borra por completo todas las colecciones raíz en Firestore (DocViz)"
    )
    parser.add_argument(
        "--credentials",
        type=Path,
        default=Path(__file__).resolve().parent / "bsg-sesion1-firebase-adminsdk-fbsvc-137f14c279.json",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Sin esto solo muestra conteos (dry-run)",
    )
    parser.add_argument("--yes", "-y", action="store_true", help="Con --execute: no pedir confirmación")
    args = parser.parse_args()

    if not args.credentials.is_file():
        print(f"ERROR: credenciales no encontradas: {args.credentials}", file=sys.stderr)
        return 2

    project_id = json.loads(args.credentials.read_text(encoding="utf-8")).get("project_id", "?")
    db = init_firestore(args.credentials)

    if args.execute and not args.yes:
        print(f"Proyecto: {project_id}")
        print("Se usará recursive_delete en CADA documento raíz de CADA colección superior.")
        ans = input("Escribe SI para continuar: ").strip()
        if ans != "SI":
            print("Cancelado.")
            return 1

    rows = wipe_all_collections(db, execute=args.execute)
    total = sum(c for _, c in rows)

    mode = "BORRADO" if args.execute else "Dry-run (sin borrar)"
    print(f"[{mode}] project_id={project_id}  (database: default)")
    for name, count in sorted(rows):
        print(f"  Colección {name!r}: {count} documento(s) raíz (cada uno = árbol completo)")
    print(f"  Total documentos raíz procesados: {total}")
    if not args.execute:
        print("\n  Para borrar de verdad:")
        print("    python firestore_wipe_docviz.py --execute --yes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
