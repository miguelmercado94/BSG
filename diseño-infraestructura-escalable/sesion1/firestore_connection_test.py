"""
Prueba de conexión a Firestore con la cuenta de servicio Firebase Admin.
Uso (desde esta carpeta sesion1):
  pip install -r requirements-firestore-test.txt
  python firestore_connection_test.py

Lee por defecto: bsg-sesion1-firebase-adminsdk-fbsvc-137f14c279.json en el mismo directorio.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Smoke test Firestore con JSON de servicio")
    parser.add_argument(
        "--credentials",
        type=Path,
        default=Path(__file__).resolve().parent / "bsg-sesion1-firebase-adminsdk-fbsvc-137f14c279.json",
        help="Ruta al JSON de firebase-adminsdk",
    )
    args = parser.parse_args()

    if not args.credentials.is_file():
        print(f"ERROR: no existe el archivo: {args.credentials}", file=sys.stderr)
        return 2

    try:
        project_id = json.loads(args.credentials.read_text(encoding="utf-8")).get("project_id", "?")
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR: no se pudo leer project_id del JSON: {e}", file=sys.stderr)
        return 2

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print("Instala dependencias: pip install -r requirements-firestore-test.txt", file=sys.stderr)
        return 3

    cred = credentials.Certificate(str(args.credentials))
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    # Lectura barata: intentar listar 1 documento de una colección del sistema o usar una lectura mínima.
    # collections() requiere permisos; si falla, igual confirmation de auth puede verse en el error.
    test_coll = "_connection_test"
    doc_ref = db.collection(test_coll).document("ping")
    doc_ref.set({"ok": True, "source": "firestore_connection_test.py"}, merge=True)
    snap = doc_ref.get()
    if not snap.exists:
        print("ERROR: escritura no reflejada al leer", file=sys.stderr)
        return 4

    data = snap.to_dict() or {}
    print("OK: Firestore respondió correctamente.")
    print(f"    project_id: {project_id}")
    print(f"    Documento de prueba: {test_coll}/ping -> {data}")
    # Limpieza opcional: borrar doc de prueba
    doc_ref.delete()
    print("    Documento de prueba eliminado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
