#!/usr/bin/env python3
"""Index the assets declared in Project.xml for private-storage extraction."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build_manifest():
    entries = {}
    # Keep IDs and destinations in sync with the asset declarations in Project.xml.
    for source, destination, library in [
        ("assets/embeds", "assets", ""),
        ("assets/fonts", "assets/fonts", ""),
        ("assets/shared", "assets/shared", ""),
        ("assets/videos", "assets/videos", "videos:"),
        ("content", "content", ""),
    ]:
        for path in sorted((ROOT / source).rglob("*")):
            if not path.is_file() or path.name.startswith(".") or path.suffix == ".fla":
                continue
            if source == "assets/shared" and path.suffix == ".mp3":
                continue
            target = f"{destination}/{path.relative_to(ROOT / source).as_posix()}"
            prefix = "android-fonts/" if path.suffix in (".ttf", ".otf") else library
            data = path.read_bytes()
            entries[target] = {
                "path": target,
                "id": prefix + target,
                "sha256": hashlib.sha256(data).hexdigest(),
                "size": len(data),
            }
    files = [entries[key] for key in sorted(entries)]
    version = hashlib.sha256(json.dumps(files, sort_keys=True).encode()).hexdigest()
    return {"version": version, "files": files}


if __name__ == "__main__":
    manifest = build_manifest()
    output = ROOT / ".android/manifest.json"
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Indexed {len(manifest['files'])} Android assets.")
