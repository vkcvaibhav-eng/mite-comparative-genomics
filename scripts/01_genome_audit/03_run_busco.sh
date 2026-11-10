#!/usr/bin/env bash
# Run BUSCO (arachnida_odb10) on every downloaded assembly in genome mode and on every
# proteome in protein mode. Finished runs are skipped, so the script can be restarted.
# Usage:  bash scripts/01_genome_audit/03_run_busco.sh [threads]
set -euo pipefail

THREADS="${1:-8}"
DATA_DIR="${DATA_DIR:-${HOME}/data/genomes}"
BUSCO_DIR="${BUSCO_DIR:-${HOME}/data/busco}"
LINEAGE="arachnida_odb10"
# Assemblies larger than this are checked in protein mode only (large tick outgroups)
MAX_GENOME_BP="${MAX_GENOME_BP:-1000000000}"

mkdir -p "${BUSCO_DIR}/genome" "${BUSCO_DIR}/protein"

for d in "${DATA_DIR}"/ncbi_dataset/data/GC*; do
    acc="$(basename "${d}")"

    genome="$(ls "${d}"/*_genomic.fna 2>/dev/null | head -n 1 || true)"
    if [ -n "${genome}" ] && [ "$(stat -c %s "${genome}")" -gt "${MAX_GENOME_BP}" ]; then
        echo "Skipping genome mode for ${acc}: assembly larger than ${MAX_GENOME_BP} bp"
        genome=""
    fi
    if [ -n "${genome}" ] && ! ls "${BUSCO_DIR}/genome/${acc}"/short_summary*.txt >/dev/null 2>&1; then
        busco -i "${genome}" -l "${LINEAGE}" -m genome -c "${THREADS}" \
            -o "${acc}" --out_path "${BUSCO_DIR}/genome" -f
    fi

    if [ -f "${d}/protein.faa" ] && ! ls "${BUSCO_DIR}/protein/${acc}"/short_summary*.txt >/dev/null 2>&1; then
        busco -i "${d}/protein.faa" -l "${LINEAGE}" -m proteins -c "${THREADS}" \
            -o "${acc}" --out_path "${BUSCO_DIR}/protein" -f
    fi
done

busco --version > "${BUSCO_DIR}/busco_version.txt"
echo "BUSCO runs complete. Next: python scripts/01_genome_audit/04_summarise_busco.py ${BUSCO_DIR}"
