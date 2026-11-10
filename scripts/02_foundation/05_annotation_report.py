#!/usr/bin/env python3
"""Compare our BRAKER annotations with the genome-mode BUSCO score and the NCBI annotation.

Usage:  python scripts/02_foundation/05_annotation_report.py ANNOT_DIR [output.tsv]

Reads ANNOT_DIR/ACCESSION/results/ for every accession found, plus register/genome_audit.tsv.
The verdict applies the acceptance rule in Section 4 of the protocol.
"""
import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCORE = re.compile(r"C:([\d.]+)%\[S:([\d.]+)%,D:([\d.]+)%\],F:([\d.]+)%,M:([\d.]+)%")
MAX_DROP = 5.0
COUNT_RANGE = (0.7, 1.5)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    annot = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "results_summaries" / "annotation" / "annotation_report.tsv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with (ROOT / "register" / "genome_audit.tsv").open() as fh:
        audit = {r["Accession"]: r for r in csv.DictReader(fh, delimiter="\t")}

    rows = []
    for res in sorted(annot.glob("*/results")):
        acc = res.parent.name
        summary = res / "busco_braker_short_summary.txt"
        counts = res / "gene_counts.tsv"
        if not summary.exists() or not counts.exists():
            continue
        m = SCORE.search(summary.read_text())
        genes, read, dropped = counts.read_text().split()
        a = audit.get(acc, {})
        g_c = a.get("BUSCO genome complete (%)", "")
        ncbi_p = a.get("BUSCO protein complete (%)", "")
        ncbi_n = a.get("Protein count", "")
        times = {}
        tfile = res.parent / "timing.tsv"
        if tfile.exists():
            for line in tfile.read_text().splitlines():
                step, hours = line.split("\t")
                times[step] = hours
        checks = []
        if g_c:
            checks.append(float(g_c) - float(m.group(1)) <= MAX_DROP)
        if ncbi_n:
            ratio = int(genes) / int(ncbi_n)
            checks.append(COUNT_RANGE[0] <= ratio <= COUNT_RANGE[1])
        verdict = "No reference" if not checks else ("Pass" if all(checks) else "Fail")
        rows.append({
            "Accession": acc,
            "Species": a.get("Species", ""),
            "BUSCO genome complete (%)": g_c,
            "BRAKER BUSCO complete (%)": m.group(1),
            "BRAKER BUSCO duplicated (%)": m.group(3),
            "BRAKER BUSCO fragmented (%)": m.group(4),
            "NCBI BUSCO protein complete (%)": ncbi_p,
            "BRAKER genes": genes,
            "NCBI protein-coding genes": ncbi_n,
            "Proteins dropped (short or internal stop)": dropped,
            "Masking (h)": times.get("mask", ""),
            "Gene prediction (h)": times.get("braker", ""),
            "Verdict": verdict,
        })
    if not rows:
        sys.exit("No finished annotations found")
    with out.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]), delimiter="\t")
        w.writeheader()
        w.writerows(rows)
    for r in rows:
        print(f"{r['Accession']}  {r['Species']}: BUSCO {r['BRAKER BUSCO complete (%)']} % "
              f"(genome mode {r['BUSCO genome complete (%)']} %), {r['BRAKER genes']} genes "
              f"(NCBI {r['NCBI protein-coding genes'] or 'none'}) -> {r['Verdict']}")
    print(f"Written to {out}")


if __name__ == "__main__":
    main()
