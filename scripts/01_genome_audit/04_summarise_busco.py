#!/usr/bin/env python3
"""Collect BUSCO short summaries into one table.

Usage:  python scripts/01_genome_audit/04_summarise_busco.py BUSCO_DIR [output.tsv]

BUSCO_DIR holds the genome/ and protein/ folders written by 03_run_busco.sh.
"""
import csv
import re
import sys
from pathlib import Path

SCORE = re.compile(
    r"C:(?P<C>[\d.]+)%\[S:(?P<S>[\d.]+)%,D:(?P<D>[\d.]+)%\],"
    r"F:(?P<F>[\d.]+)%,M:(?P<M>[\d.]+)%,n:(?P<n>\d+)"
)


def read_summary(path):
    for line in path.read_text().splitlines():
        match = SCORE.search(line)
        if match:
            return match.groupdict()
    return None


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    busco_dir = Path(sys.argv[1])
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
        "results_summaries/genome_audit/busco_summary.tsv"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)

    rows = []
    for mode in ("genome", "protein"):
        mode_dir = busco_dir / mode
        if not mode_dir.is_dir():
            continue
        for run_dir in sorted(p for p in mode_dir.iterdir() if p.is_dir()):
            summaries = sorted(run_dir.glob("short_summary*.txt"))
            if not summaries:
                continue
            scores = read_summary(summaries[0])
            if scores is None:
                print(f"No score line found in {summaries[0]}", file=sys.stderr)
                continue
            rows.append(
                {
                    "accession": run_dir.name,
                    "mode": mode,
                    "complete_pct": scores["C"],
                    "single_pct": scores["S"],
                    "duplicated_pct": scores["D"],
                    "fragmented_pct": scores["F"],
                    "missing_pct": scores["M"],
                    "n_buscos": scores["n"],
                }
            )

    fields = [
        "accession", "mode", "complete_pct", "single_pct", "duplicated_pct",
        "fragmented_pct", "missing_pct", "n_buscos",
    ]
    with out_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{len(rows)} BUSCO runs written to {out_path}")


if __name__ == "__main__":
    main()
