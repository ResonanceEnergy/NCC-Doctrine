#!/usr/bin/env python3
"""Repo validation checks (skeleton).

Checks to implement:
- Required folders exist
- Only one params.json (canonical path)
- Import_Config.json present
- No duplicate canonical workbooks in tracked paths
"""

from pathlib import Path

REQUIRED_DIRS = ['docs', 'cad', 'automation', 'tests', 'data']


def main():
    root = Path(__file__).resolve().parents[2]
    missing = [d for d in REQUIRED_DIRS if not (root/d).exists()]
    if missing:
        raise SystemExit(f"Missing required dirs: {missing}")
    print('[OK] basic structure present')


if __name__ == '__main__':
    main()
