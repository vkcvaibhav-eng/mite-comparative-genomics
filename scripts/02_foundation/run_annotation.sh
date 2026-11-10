#!/usr/bin/env bash
# Mask, annotate and check every accession in a list, one after another, recording the
# time each step takes. Finished steps are skipped, so the script can be restarted.
# Usage:  bash scripts/02_foundation/run_annotation.sh LIST BUCKET [threads] [shutdown]
#   LIST     : file with one accession per line
#   BUCKET   : e.g. gs://vkc-mite-genomics
#   shutdown : if given as the fourth argument, the VM powers off when the script ends,
#              whether it finished or failed, so that it stops costing money
set -uo pipefail

LIST="$(realpath "${1:?Give the accession list}")"
BUCKET="${2:?Give the bucket, e.g. gs://my-bucket}"
THREADS="${3:-8}"
SHUTDOWN="${4:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
export ANNOT_DIR="${ANNOT_DIR:-${HOME}/data/annotation}"
mkdir -p "${ANNOT_DIR}"
LOG="${ANNOT_DIR}/run_$(date +%F_%H%M).log"

finish() {
    python "${HERE}/05_annotation_report.py" "${ANNOT_DIR}" >> "${LOG}" 2>&1
    gcloud storage cp "${LOG}" "${BUCKET}/annotation/logs/" >/dev/null 2>&1
    gcloud storage cp "${REPO}/results_summaries/annotation/annotation_report.tsv" "${BUCKET}/annotation/" >/dev/null 2>&1
    if [ "${SHUTDOWN}" = "shutdown" ]; then
        echo "Powering off the VM" | tee -a "${LOG}"
        sudo shutdown -h +1
    fi
}
trap finish EXIT

hours() { awk -v s="$1" -v e="$2" 'BEGIN { printf "%.2f", (e - s) / 3600 }'; }

command -v busco >/dev/null 2>&1 || { echo "Activate the environment first: conda activate mite-audit" | tee -a "${LOG}"; exit 1; }

while read -r ACC; do
    [ -z "${ACC}" ] && continue
    W="${ANNOT_DIR}/${ACC}"
    mkdir -p "${W}"
    echo "=== ${ACC} started $(date)" | tee -a "${LOG}"

    if [ ! -s "${W}/genome.softmasked.fa" ]; then
        t0=$(date +%s)
        bash "${HERE}/01_mask_repeats.sh" "${ACC}" "${THREADS}" >> "${LOG}" 2>&1 || { echo "${ACC}: masking FAILED" | tee -a "${LOG}"; continue; }
        printf "mask\t%s\n" "$(hours "${t0}" "$(date +%s)")" > "${W}/timing.tsv"
    fi
    if [ ! -s "${W}/braker/braker.aa" ]; then
        t0=$(date +%s)
        bash "${HERE}/02_annotate_braker.sh" "${ACC}" "${THREADS}" >> "${LOG}" 2>&1 || { echo "${ACC}: gene prediction FAILED" | tee -a "${LOG}"; continue; }
        printf "braker\t%s\n" "$(hours "${t0}" "$(date +%s)")" >> "${W}/timing.tsv"
    fi
    bash "${HERE}/04_check_annotation.sh" "${ACC}" "${THREADS}" >> "${LOG}" 2>&1 || { echo "${ACC}: check FAILED" | tee -a "${LOG}"; continue; }
    cp "${W}/timing.tsv" "${W}/results/" 2>/dev/null
    gcloud storage rsync --recursive "${W}/results" "${BUCKET}/annotation/${ACC}" >> "${LOG}" 2>&1
    echo "=== ${ACC} finished $(date)" | tee -a "${LOG}"
done < "${LIST}"

echo "All accessions processed. Log: ${LOG}" | tee -a "${LOG}"
