#!/usr/bin/env python3
"""MicroHydroV1 - Measurements Importer (skeleton)

Replace this file with the validated importer used to append CSV rows into the
canonical RnD workbook. Keep CLI stable so tooling and SOPs do not break.

Expected CSV columns (minimum):
- Timestamp, Test_ID, Sensor, Value, Unit
Optional:
- Baseline_Value, Conditions, Notes
"""

import argparse
from pathlib import Path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--workbook', required=True, help='Path to MicroHydroV1_RnD_Export.xlsx')
    ap.add_argument('--csv', nargs='+', required=True, help='CSV file(s) to import')
    args = ap.parse_args()

    wb = Path(args.workbook)
    csvs = [Path(p) for p in args.csv]

    print('[SKEL] Workbook:', wb)
    print('[SKEL] CSVs:', ', '.join(p.name for p in csvs))
    print('[SKEL] Replace importer with validated version.')


if __name__ == '__main__':
    main()
