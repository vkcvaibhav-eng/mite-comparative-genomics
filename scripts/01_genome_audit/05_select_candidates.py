#!/usr/bin/env python3
"""Choose one assembly per species from the NCBI listings and build the download list.

Usage:  python scripts/01_genome_audit/05_select_candidates.py DATE
        DATE is the date stamp of the listing files, e.g. 2026-11-10

Choice of assembly within a species, in this order:
  1. RefSeq assembly with NCBI annotation
  2. GenBank assembly with submitter annotation and scaffold N50 >= 100 kb
  3. highest scaffold N50
Ties are settled by scaffold N50.

Batch 1 = every focal species plus the outgroups marked in taxonomy.tsv, provided
scaffold N50 >= 20 kb. Assemblies below that are listed but not downloaded.
"""
import csv
import sys
from collections import defaultdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parents[1] / "results_summaries" / "genome_audit"
MIN_N50 = 20_000
ANNOT_N50 = 100_000


def load_taxonomy():
    with (HERE / "taxonomy.tsv").open() as fh:
        return {r["name"]: r for r in csv.DictReader(fh, delimiter="\t")}


def classify(species, source, tax):
    hit = tax.get(species) or tax.get(species.split()[0])
    if hit:
        return hit["family"], hit["group"], hit["feeding"], hit["tier"]
    if source == "Parasitiformes":
        return "", "Ixodida", "Haematophagous", "other"
    return "", "Oribatida", "Detritivorous or fungivorous", "other"


def to_int(value):
    return int(value) if value else 0


def rank(row):
    n50 = to_int(row["Assembly Stats Scaffold N50"])
    annotated = bool(row["Annotation Count Gene Protein-coding"])
    refseq = row["Assembly Accession"].startswith("GCF_")
    if refseq and annotated:
        cls = 3
    elif annotated and n50 >= ANNOT_N50:
        cls = 2
    else:
        cls = 1
    return (cls, n50)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    date = sys.argv[1]
    tax = load_taxonomy()

    by_species = defaultdict(list)
    for source in ("Acariformes", "Parasitiformes"):
        path = OUT / f"ncbi_genomes_{source}_{date}.tsv"
        with path.open() as fh:
            for row in csv.DictReader(fh, delimiter="\t"):
                row["source"] = source
                by_species[row["Organism Name"]].append(row)

    records = []
    for species, rows in by_species.items():
        best = max(rows, key=rank)
        family, group, feeding, tier = classify(species, best["source"], tax)
        n50 = to_int(best["Assembly Stats Scaffold N50"])
        if tier == "other":
            batch = "not selected"
        elif n50 < MIN_N50:
            batch = "too fragmented"
        else:
            batch = "batch 1"
        records.append({
            "Species": species,
            "Family": family,
            "Order / group": group,
            "Feeding type": feeding,
            "Tier": tier,
            "Accession": best["Assembly Accession"],
            "Assembly level": best["Assembly Level"],
            "Genome size (Mb)": f"{to_int(best['Assembly Stats Total Sequence Length']) / 1e6:.1f}",
            "Scaffold N50 (kb)": f"{n50 / 1e3:.1f}",
            "NCBI annotation": "Yes" if best["Annotation Count Gene Protein-coding"] else "No",
            "Protein-coding genes": best["Annotation Count Gene Protein-coding"],
            "Assemblies at NCBI": len(rows),
            "Decision": batch,
        })

    order = {"focal": 0, "outgroup": 1, "other": 2}
    records.sort(key=lambda r: (order[r["Tier"]], r["Order / group"], r["Family"], r["Species"]))

    table = OUT / f"candidate_genomes_{date}.tsv"
    with table.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(records[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(records)

    batch1 = [r for r in records if r["Decision"] == "batch 1"]
    (OUT / "accessions_batch1.txt").write_text(
        "".join(r["Accession"] + "\n" for r in batch1)
    )

    print(f"{sum(len(v) for v in by_species.values())} assemblies, {len(records)} species")
    print(f"{len(batch1)} species in batch 1 -> {OUT / 'accessions_batch1.txt'}")
    print(f"Full table -> {table}")


if __name__ == "__main__":
    main()
