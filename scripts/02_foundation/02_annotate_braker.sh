#!/usr/bin/env bash
# Predict protein-coding genes on one soft-masked assembly with BRAKER in protein-evidence
# mode (ProtHint, GeneMark-EP+, AUGUSTUS), using the teambraker/braker3 container.
# Usage:  bash scripts/02_foundation/02_annotate_braker.sh ACCESSION [threads]
set -euo pipefail

ACC="${1:?Give an assembly accession}"
THREADS="${2:-8}"
WORK="${ANNOT_DIR:-${HOME}/data/annotation}/${ACC}"
PROT="${ORTHODB_DIR:-${HOME}/data/orthodb}/Arthropoda.fa"
SPECIES="mite_$(echo "${ACC}" | tr '.' '_')"

if [ -s "${WORK}/braker/braker.aa" ]; then
    echo "${ACC}: already annotated, skipping"; exit 0
fi
[ -s "${WORK}/genome.softmasked.fa" ] || { echo "${ACC}: run 01_mask_repeats.sh first" >&2; exit 1; }
[ -s "${PROT}" ] || { echo "Protein evidence not found: ${PROT}" >&2; exit 1; }

# The container runs as user 1000:100, so it needs write access to the work folder
rm -rf "${WORK}/braker" "${WORK}/augustus_config/species/${SPECIES}"
mkdir -p "${WORK}/braker"
chmod -R a+rwX "${WORK}"

sudo docker run --rm --user 1000:100 \
    -v "${WORK}:/work" -v "$(dirname "${PROT}"):/prot:ro" \
    teambraker/braker3:latest bash -c "
        set -euo pipefail
        [ -d /work/augustus_config ] || cp -r \"\${AUGUSTUS_CONFIG_PATH:-/opt/Augustus/config}\" /work/augustus_config
        braker.pl --genome=/work/genome.softmasked.fa --prot_seq=/prot/$(basename "${PROT}") \
            --threads=${THREADS} --workingdir=/work/braker --species=${SPECIES} --gff3 \
            --AUGUSTUS_CONFIG_PATH=/work/augustus_config
    "

[ -s "${WORK}/braker/braker.aa" ] || { echo "${ACC}: BRAKER wrote no protein file" >&2; exit 1; }
echo "${ACC}: annotation at ${WORK}/braker"
