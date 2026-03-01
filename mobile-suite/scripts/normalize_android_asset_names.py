#!/usr/bin/env python3
"""
Normalize asset filenames to Android-friendly resource names.
Default: dry-run
Use --apply to actually rename.

Rule:
- lowercase
- [a-z0-9_] only
- collapse repeats
- prefix with a_ if starts with digit
"""
from pathlib import Path
import argparse
import re

ROOT = Path(__file__).resolve().parents[1] / 'common'
ALLOWED_EXT = {'.png', '.webp', '.jpg', '.jpeg', '.svg', '.ogg', '.wav', '.mp3', '.ttf', '.otf', '.json'}


def sanitize(stem: str) -> str:
    s = stem.lower()
    s = re.sub(r'[^a-z0-9]+', '_', s)
    s = re.sub(r'_+', '_', s).strip('_')
    if not s:
        s = 'asset'
    if s[0].isdigit():
        s = 'a_' + s
    return s


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    i = 2
    while True:
        p = path.with_name(f"{path.stem}_{i}{path.suffix}")
        if not p.exists():
            return p
        i += 1


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--apply', action='store_true', help='Apply rename changes')
    args = parser.parse_args()

    files = [p for p in ROOT.rglob('*') if p.is_file() and p.suffix.lower() in ALLOWED_EXT and p.name != '.gitkeep']

    changes = []
    for src in files:
        new_name = sanitize(src.stem) + src.suffix.lower()
        if src.name != new_name:
            dst = src.with_name(new_name)
            dst = unique_path(dst)
            changes.append((src, dst))

    print(f"ROOT={ROOT}")
    print(f"CANDIDATES={len(changes)}")

    for src, dst in changes[:200]:
        print(f"{src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")

    if not args.apply:
        print("DRY_RUN_ONLY (use --apply to rename)")
        return

    for src, dst in changes:
        src.rename(dst)

    print(f"RENAMED={len(changes)}")


if __name__ == '__main__':
    main()
