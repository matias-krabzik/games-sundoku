#!/usr/bin/env python3
"""Build the isolated YouTube variant and a reproducible ZIP."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import zipfile


ROOT = pathlib.Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "youtube_playables"
ARCHIVE = ROOT / "build" / "sundoku-youtube-playables.zip"
SDK_SCRIPT = '<script src="https://www.youtube.com/game_api/v1"></script>'


def main() -> None:
    command = [
        "flutter", "build", "web", "--release",
        "--dart-define=YOUTUBE_PLAYABLES=true",
        "--no-web-resources-cdn", "--base-href", "/playables/",
        "--output", str(OUTPUT),
    ]
    subprocess.run(command, cwd=ROOT, check=True)

    index = OUTPUT / "index.html"
    html = index.read_text(encoding="utf-8")
    html, base_count = re.subn(r'<base href="/playables/">',
                               '<base href="./">', html, count=1)
    if base_count != 1:
        raise RuntimeError("Flutter index.html has an unexpected base href")
    marker = '<script src="flutter_bootstrap.js" async></script>'
    if html.count(marker) != 1:
        raise RuntimeError("Flutter bootstrap tag changed; verify SDK order")
    html = html.replace(marker, SDK_SCRIPT + '\n  '
                        + '<script src="flutter_bootstrap.js"></script>')
    index.write_text(html, encoding="utf-8")

    bootstrap = OUTPUT / "flutter_bootstrap.js"
    script = bootstrap.read_text(encoding="utf-8")
    script, worker_count = re.subn(
        r"_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{.*?\}\s*\}\);",
        "_flutter.loader.load();", script, count=1, flags=re.DOTALL)
    if worker_count != 1:
        raise RuntimeError("Flutter service worker bootstrap changed")
    bootstrap.write_text(script, encoding="utf-8")

    # These files belong to the ordinary web build's SQLite store.
    for unused in ("sqflite_sw.js", "sqlite3.wasm",
                   "flutter_service_worker.js", ".last_build_id"):
        (OUTPUT / unused).unlink(missing_ok=True)
    for hidden in OUTPUT.rglob(".DS_Store"):
        hidden.unlink()

    files = sorted(path for path in OUTPUT.rglob("*") if path.is_file())
    total = 0
    for path in files:
        relative = path.relative_to(OUTPUT)
        if any(not re.fullmatch(r"[A-Za-z0-9_.-]+", part)
               for part in relative.parts):
            raise RuntimeError(f"Unsupported Playables filename: {relative}")
        size = path.stat().st_size
        if size >= 30 * 1024 * 1024:
            raise RuntimeError(f"File exceeds 30 MiB: {relative}")
        total += size
    if total >= 250 * 1024 * 1024:
        raise RuntimeError("Playables package exceeds 250 MiB")
    if len(files) > 8000:
        raise RuntimeError("Playables package exceeds 8000 files")

    ARCHIVE.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(ARCHIVE, "w", zipfile.ZIP_DEFLATED,
                         compresslevel=9) as bundle:
        for path in files:
            relative = path.relative_to(OUTPUT).as_posix()
            info = zipfile.ZipInfo(relative, date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            bundle.writestr(info, path.read_bytes(), compress_type=zipfile.ZIP_DEFLATED,
                            compresslevel=9)
    print(f"Build: {OUTPUT}")
    print(f"ZIP: {ARCHIVE} ({ARCHIVE.stat().st_size / 1024 / 1024:.1f} MiB)")
    print(f"Total files: {len(files)}; uncompressed: {total / 1024 / 1024:.1f} MiB")
    print("Initial download must be measured through gameReady in the SDK Test Suite.")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, RuntimeError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
