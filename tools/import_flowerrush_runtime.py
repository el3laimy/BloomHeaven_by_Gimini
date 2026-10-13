#!/usr/bin/env python3
"""Safe, opt-in FlowerRush runtime PNG import into BloomHeaven by Gemini."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "tools" / "flowerrush_asset_inventory.json"
COUNTS = {"flowers": 100, "garden": 8, "tools": 8, "hud": 15}


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()


def read_inventory(path: Path = INVENTORY) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 1:
        raise ValueError("Unsupported inventory")
    items = manifest.get("items", [])
    if not isinstance(items, list) or len(items) != sum(COUNTS.values()):
        raise ValueError("Unexpected inventory length")
    groups = dict.fromkeys(COUNTS, 0)
    targets = set()
    for item in items:
        category = item.get("group")
        if category not in COUNTS:
            raise ValueError("Invalid group")
        sp, dp = Path(item["source_path"]), Path(item["target_path"])
        if (sp.is_absolute() or dp.is_absolute()
                or ".." in sp.parts or ".." in dp.parts
                or sp.suffix.lower() != ".png" or dp.suffix.lower() != ".png"
                or not sp.as_posix().startswith("assets/")
                or not dp.as_posix().startswith("assets/reused/flowerrush/")
                or "source" in sp.parts or "quarantine" in sp.parts):
            raise ValueError("Unsafe source or destination: " + str(sp))
        if dp in targets:
            raise ValueError("Duplicated destination: " + str(dp))
        targets.add(dp)
        groups[category] += 1
    if groups != COUNTS:
        raise ValueError("Unexpected category counts: " + str(groups))
    return manifest


def transfer(source_root: Path, target_root: Path, entries: list[dict], apply: bool) -> dict:
    """Verify every input and collision before starting writes; never overwrite."""
    source_root, target_root = source_root.resolve(), target_root.resolve()
    if source_root == target_root:
        raise ValueError("Source and destination must differ")
    if not (source_root / "project.godot").is_file():
        raise ValueError("Source project.godot missing")
    if not (target_root / "project.godot").is_file():
        raise ValueError("Destination project.godot missing")
    missing, unchanged, issues = [], 0, []
    for item in entries:
        s = (source_root / item["source_path"]).resolve()
        d = (target_root / item["target_path"]).resolve()
        if not s.is_relative_to(source_root) or not d.is_relative_to(target_root):
            issues.append("Out-of-tree path: " + item["source_path"])
            continue
        if not s.is_file():
            issues.append("Missing source: " + item["source_path"])
            continue
        payload = s.read_bytes()
        if len(payload) != item["bytes"] or git_blob_sha(payload) != item["git_blob_sha"]:
            issues.append("Source differs from pinned commit: " + item["source_path"])
            continue
        if d.exists():
            if not d.is_file() or d.read_bytes() != payload:
                issues.append("Destination collision; refusing overwrite: " + item["target_path"])
            else:
                unchanged += 1
        else:
            missing.append((d, payload))
    if issues:
        raise RuntimeError("\n".join(issues))
    if apply:
        for destination, content in missing:
            destination.parent.mkdir(parents=True, exist_ok=True)
            temporary = None
            try:
                with tempfile.NamedTemporaryFile(dir=destination.parent, prefix=".flower-rush-", delete=False) as fp:
                    temporary = Path(fp.name)
                    fp.write(content)
                if destination.exists():
                    raise RuntimeError("Destination appeared during transfer: " + str(destination))
                os.replace(temporary, destination)
            finally:
                if temporary is not None:
                    temporary.unlink(missing_ok=True)
    return {"selected": len(entries), "already_identical": unchanged,
            "missing": len(missing), "copied": len(missing) if apply else 0}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--destination", default=ROOT, type=Path)
    parser.add_argument("--groups", nargs="+", choices=sorted(COUNTS), default=sorted(COUNTS))
    parser.add_argument("--apply", action="store_true", help="Actually copy missing assets; default is dry-run")
    args = parser.parse_args()
    selected = [item for item in read_inventory()["items"] if item["group"] in args.groups]
    results = transfer(args.source, args.destination, selected, args.apply)
    print(json.dumps({"mode": "apply" if args.apply else "dry-run", **results}, indent=2))
    print("Existing target files and scripts unchanged. Source assets remain untouched.")
    print("WARNING: Target GitHub repo is public; development candidates need rights/release review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
