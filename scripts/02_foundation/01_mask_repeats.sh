#!/usr/bin/env bash
# Build a de novo repeat library for one assembly (RepeatModeler) and soft-mask the
# genome with it (RepeatMasker), using the dfam/tetools container.
# Usage:  bash scripts/02_foundation/01_mask_repeats.sh ACCESSION [threads]
set -euo pipefail

ACC="${1:?Give an assembly accession}"
THREADS="${2:-8}"
DATA_DIR="${DATA_DIR:-${HOME}/data/genomes}"
WORK="${ANNOT_DIR:-${HOME}/data/annotation}/${ACC}"
PA=$(( THREADS / 4 )); [ "${PA}" -lt 1 ] && PA=1   # RepeatMasker uses 4 threads per job

if [ -s "${WORK}/genome.softmasked.fa" ]; then
    echo "${ACC}: already masked, skipping"; exit 0
fi

SRC="$(ls "${DATA_DIR}/ncbi_dataset/data/${ACC}"/*_genomic.fna | head -n 1)"
mkdir -p "${WORK}/repeats"
# Sequence names cut at the first space: gene predictors need simple names
cut -d' ' -f1 "${SRC}" > "${WORK}/genome.fa"

sudo docker run --rm --user "$(id -u):$(id -g)" -e HOME=/work \
    -v "${WORK}:/work" -w /work/repeats dfam/tetools:latest bash -c "
        set -euo pipefail
        [ -s db-families.fa ] || { BuildDatabase -name db ../genome.fa && RepeatModeler -database db -threads ${THREADS} -LTRStruct; }
        RepeatMasker -pa ${PA} -lib db-families.fa -xsmall -gff -dir . ../genome.fa
    "

if [ ! -s "${WORK}/repeats/genome.fa.masked" ]; then
    echo "${ACC}: RepeatMasker wrote no masked genome" >&2; exit 1
fi
cp "${WORK}/repeats/genome.fa.masked" "${WORK}/genome.softmasked.fa"
echo "${ACC}: masked genome at ${WORK}/genome.softmasked.fa"
