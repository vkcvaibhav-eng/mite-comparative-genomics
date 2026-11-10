#!/usr/bin/env bash
# List every public genome assembly for the taxa in taxa.txt, with assembly and
# annotation statistics from NCBI. Output: one TSV per taxon, dated.
# Usage:  bash scripts/01_genome_audit/01_list_public_genomes.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUT_DIR="${REPO_ROOT}/results_summaries/genome_audit"
TODAY="$(date +%F)"
mkdir -p "${OUT_DIR}"

FIELDS="accession,organism-name,organism-tax-id,assminfo-level,assminfo-release-date,assminfo-submitter,assmstats-total-sequence-len,assmstats-contig-n50,assmstats-scaffold-n50,assmstats-number-of-scaffolds,annotinfo-name,annotinfo-provider,annotinfo-release-date,annotinfo-featcount-gene-protein-coding"

while read -r taxon; do
    [ -z "${taxon}" ] && continue
    out="${OUT_DIR}/ncbi_genomes_${taxon// /_}_${TODAY}.tsv"
    echo "Querying NCBI for ${taxon}"
    datasets summary genome taxon "${taxon}" --as-json-lines \
        | dataformat tsv genome --fields "${FIELDS}" > "${out}"
    echo "  $(($(wc -l < "${out}") - 1)) assemblies -> ${out}"
done < "${SCRIPT_DIR}/taxa.txt"

datasets --version > "${OUT_DIR}/ncbi_datasets_version_${TODAY}.txt"
