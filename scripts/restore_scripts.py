#!/usr/bin/env python3
import filecmp
import hashlib
import os
import shutil
import stat
import sys
from pathlib import Path

CANONICAL_DIR = Path(os.path.expanduser("~/.local/share/axiom/python-scripts"))
USER_SCRIPTS_DIR = Path(os.path.expanduser("~/scripts"))


def sha256sum(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_executable(path: Path) -> None:
    mode = path.stat().st_mode
    path.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def prompt_overwrite(rel: str) -> bool:
    try:
        ans = input(f"Overwrite {rel}? [y/N] ").strip().lower()
    except EOFError:
        return False
    return ans in {"y", "yes"}


def main() -> int:
    if not CANONICAL_DIR.exists():
        print(f"Canonical directory not found: {CANONICAL_DIR}", file=sys.stderr)
        return 1

    USER_SCRIPTS_DIR.mkdir(parents=True, exist_ok=True)

    canon_files = sorted([p for p in CANONICAL_DIR.iterdir() if p.is_file() and p.suffix == ".py"])
    if not canon_files:
        print("No canonical Python scripts found.")
        return 0

    for src in canon_files:
        dest = USER_SCRIPTS_DIR / src.name
        rel = dest.relative_to(Path.home())
        if not dest.exists():
            shutil.copy2(src, dest)
            ensure_executable(dest)
            print(f"Created {rel}")
            continue

        # If identical, skip
        try:
            same = sha256sum(src) == sha256sum(dest)
        except Exception:
            same = filecmp.cmp(src, dest, shallow=False)

        if same:
            print(f"Unchanged {rel}, skipping")
            continue

        if prompt_overwrite(str(rel)):
            shutil.copy2(src, dest)
            ensure_executable(dest)
            print(f"Overwrote {rel}")
        else:
            print(f"Skipped {rel}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())