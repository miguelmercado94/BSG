"""Convierte ENTREGABLE.md a PDF con Chrome headless (sin pandoc). Uso: python md_to_pdf_chrome.py"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

import markdown

# Raíz: sesion1 (padre de scripts/)
ROOT = Path(__file__).resolve().parent.parent
CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")

CSS = """
@page { margin: 18mm; }
body { font-family: 'Segoe UI', Calibri, Arial, sans-serif; font-size: 11pt; line-height: 1.45; color: #222; max-width: 210mm; margin: 0 auto; }
h1 { font-size: 22pt; border-bottom: 1px solid #ccc; padding-bottom: 0.2em; }
h2 { font-size: 15pt; margin-top: 1.2em; }
h3 { font-size: 13pt; }
pre { background: #f6f8fa; padding: 10px; border-radius: 6px; overflow-x: auto; font-size: 9pt; white-space: pre-wrap; }
code { font-family: Consolas, 'Courier New', monospace; font-size: 0.95em; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; font-size: 10pt; }
th, td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; }
blockquote { border-left: 4px solid #ddd; margin-left: 0; padding-left: 12px; color: #444; }
a { color: #0366d6; }
hr { border: none; border-top: 1px solid #e0e0e0; margin: 1.5em 0; }
"""


def to_file_url(path: Path) -> str:
    p = path.resolve()
    s = p.as_posix()
    if s.startswith("//"):
        return "file:" + s
    if len(s) >= 2 and s[1] == ":":
        return "file:///" + s
    return "file://" + s


def main() -> int:
    md_in = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "ENTREGABLE.md"
    pdf_out = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "ENTREGABLE.pdf"
    if not md_in.is_file():
        print(f"ERROR: no existe {md_in}", file=sys.stderr)
        return 1
    if not CHROME.is_file():
        print(f"ERROR: no se encontró Chrome en {CHROME}", file=sys.stderr)
        return 2

    text = md_in.read_text(encoding="utf-8")
    body = markdown.markdown(
        text,
        extensions=["tables", "fenced_code", "nl2br"],
    )
    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width" />
<title>ENTREGABLE</title>
<style>{CSS}</style>
</head>
<body>
{body}
</body>
</html>"""
    tmp = md_in.parent / "_ENTREGABLE_print.html"
    tmp.write_text(html, encoding="utf-8")
    file_url = to_file_url(tmp)
    try:
        subprocess.run(
            [
                str(CHROME),
                "--headless=new",
                "--disable-gpu",
                f"--print-to-pdf={pdf_out.resolve()}",
                file_url,
            ],
            check=True,
            timeout=120,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(e.stderr or e.stdout or e, file=sys.stderr)
        return 3
    finally:
        if tmp.is_file():
            tmp.unlink(missing_ok=True)

    print(f"OK: {pdf_out.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
