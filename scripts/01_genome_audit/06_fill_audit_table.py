#!/usr/bin/env python3
"""Merge the candidate table and the BUSCO summary into register/genome_audit.tsv.

Usage:  python scripts/01_genome_audit/06_fill_audit_table.py DATE
        DATE is the date stamp of candidate_genomes_DATE.tsv

Status follows Section 3 of the protocol. Duplication in protein mode is not judged
here because NCBI protein files hold every isoform; it is re-measured on the
one-protein-per-gene set in Phase 2.
"""
import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUDIT = ROOT / "results_summaries" / "genome_audit"


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    date = sys.argv[1]
    with (AUDIT / f"candidate_genomes_{date}.tsv").open() as fh:
        cands = [r for r in csv.DictReader(fh, delimiter="\t") if r["Decision"] == "batch 1"]
    busco = {}
    with (AUDIT / "busco_summary.tsv").open() as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            busco[(r["accession"], r["mode"])] = r

    header = [
        "Species", "Family", "Order / group", "Feeding type", "Accession",
        "Assembly level", "Genome size (Mb)", "Scaffold N50 (kb)",
        "BUSCO genome complete (%)", "BUSCO genome duplicated (%)",
        "BUSCO protein complete (%)", "BUSCO protein duplicated (%)",
        "Annotation available", "Protein count", "Include?", "Notes",
    ]
    rows = []
    for c in cands:
        g = busco.get((c["Accession"], "genome"))
        p = busco.get((c["Accession"], "protein"))
        gc = float(g["complete_pct"]) if g else None
        gd = float(g["duplicated_pct"]) if g else None
        pc = float(p["complete_pct"]) if p else None
        notes = []
        if p and pc >= 80:
            status = "Yes: proteome passes completeness"
        elif p and pc < 60 and gc is not None and gc >= 60:
            status = "Annotation rejected; genome 60 to 80 %, species tree only under current rule"
        elif gc is None:
            status = "Undetermined"
        elif gc >= 80:
            status = "Needs annotation; genome passes completeness"
        elif gc >= 60:
            status = "Genome 60 to 80 %: species tree only under current rule"
        else:
            status = "Genome below 60 %: excluded under current rule"
        if g is None:
            notes.append("Genome mode not run (assembly larger than 1 Gb)")
        if gd is not None and gd >= 10:
            notes.append("Genome duplication 10 % or more: check for uncollapsed haplotypes")
        if gc is not None and gc < 80 and float(g["fragmented_pct"]) < 2:
            notes.append("Low completeness with few fragmented genes: possible lineage gene loss, decision pending")
        notes.append("Feeding type to be checked against the literature")
        rows.append([
            c["Species"], c["Family"], c["Order / group"], c["Feeding type"], c["Accession"],
            c["Assembly level"], c["Genome size (Mb)"], c["Scaffold N50 (kb)"],
            g["complete_pct"] if g else "", g["duplicated_pct"] if g else "",
            p["complete_pct"] if p else "", p["duplicated_pct"] if p else "",
            "Yes (NCBI)" if c["NCBI annotation"] == "Yes" else "Not at NCBI",
            c["Protein-coding genes"], status, "; ".join(notes),
        ])
    with (ROOT / "register" / "genome_audit.tsv").open("w", newline="") as fh:
        w = csv.writer(fh, delimiter="\t", lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)
    counts = {}
    for r in rows:
        counts[r[14]] = counts.get(r[14], 0) + 1
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print(f"{v:3d}  {k}")


if __name__ == "__main__":
    main()
