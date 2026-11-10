#!/usr/bin/env bash
# Reduce a BRAKER annotation to one protein per gene, run BUSCO on it in protein mode and
# copy the key files to a results folder. Needs the mite-audit conda environment.
# Usage:  bash scripts/02_foundation/04_check_annotation.sh ACCESSION [threads]
set -euo pipefail

ACC="${1:?Give an assembly accession}"
THREADS="${2:-8}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${ANNOT_DIR:-${HOME}/data/annotation}/${ACC}"
BUSCO_DIR="${BUSCO_DIR:-${HOME}/data/busco}/protein_braker"
RES="${WORK}/results"

command -v busco >/dev/null 2>&1 || { echo "Activate the environment first: conda activate mite-audit" >&2; exit 1; }
mkdir -p "${RES}" "${BUSCO_DIR}"

python "${HERE}/03_longest_isoform.py" "${WORK}/braker/braker.aa" "${RES}/${ACC}.braker.longest.faa" \
    > "${RES}/gene_counts.tsv"

if ! ls "${BUSCO_DIR}/${ACC}"/short_summary*.txt >/dev/null 2>&1; then
    busco -i "${RES}/${ACC}.braker.longest.faa" -l arachnida_odb10 -m proteins -c "${THREADS}" \
        -o "${ACC}" --out_path "${BUSCO_DIR}" -f
fi
cp "${BUSCO_DIR}/${ACC}"/short_summary*.txt "${RES}/busco_braker_short_summary.txt"

for f in braker.gtf braker.gff3 braker.aa braker.codingseq; do
    [ -f "${WORK}/braker/${f}" ] && cp "${WORK}/braker/${f}" "${RES}/${ACC}.${f}"
done
cp "${WORK}/genome.softmasked.fa" "${RES}/${ACC}.softmasked.fa"
cp "${WORK}/repeats/db-families.fa" "${RES}/${ACC}.repeat_library.fa"
cp "${WORK}/repeats/genome.fa.tbl" "${RES}/${ACC}.repeat_summary.tbl" 2>/dev/null || true
echo "${ACC}: results in ${RES}"
