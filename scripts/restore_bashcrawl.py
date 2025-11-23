#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path

CANONICAL_DIR = Path(os.path.expanduser("~/.local/share/axiom/bashcrawl"))
USER_BASHCRAWL_DIR = Path(os.path.expanduser("~/bashcrawl"))


def prompt_overwrite() -> bool:
    try:
        ans = input(f"Overwrite ~/bashcrawl? [y/N] ").strip().lower()
    except EOFError:
        return False
    return ans in {"y", "yes"}


def main() -> int:
    if not CANONICAL_DIR.exists():
        print(f"Canonical directory not found: {CANONICAL_DIR}", file=sys.stderr)
        return 1

    # Check if entrance file exists (verifies it's a valid bashcrawl directory)
    entrance = CANONICAL_DIR / "entrance"
    if not entrance.exists():
        print(f"Canonical bashcrawl appears invalid (no entrance directory)", file=sys.stderr)
        return 1

    if USER_BASHCRAWL_DIR.exists():
        print(f"~/bashcrawl already exists.")
        if not prompt_overwrite():
            print("Cancelled.")
            return 0
        
        print("Removing existing ~/bashcrawl...")
        shutil.rmtree(USER_BASHCRAWL_DIR)

    print(f"Copying pristine bashcrawl to ~/bashcrawl...")
    shutil.copytree(CANONICAL_DIR, USER_BASHCRAWL_DIR, symlinks=False)
    print("Restored bashcrawl to pristine state.")
    
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
