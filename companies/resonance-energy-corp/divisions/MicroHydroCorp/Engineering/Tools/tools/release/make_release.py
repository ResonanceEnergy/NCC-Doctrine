#!/usr/bin/env python3
"""Create a release bundle (skeleton).

This script should:
1) Collect canonical docs + procedures + STW matrix
2) Collect latest test plots + drawings
3) Optionally collect CAD exports
4) Write a manifest (hashes + versions)
5) Zip into MicroHydroV1_Release_vX.Y.Z.zip

Replace with your final release automation.
"""

import argparse
from pathlib import Path
import zipfile


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--version', required=True, help='Release version, e.g., v0.2.0')
    ap.add_argument('--out', default='dist', help='Output folder')
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    zip_name = out_dir / f"MicroHydroV1_Release_{args.version}.zip"
    with zipfile.ZipFile(zip_name, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        # TODO: add files here
        pass

    print('Created:', zip_name)


if __name__ == '__main__':
    main()
