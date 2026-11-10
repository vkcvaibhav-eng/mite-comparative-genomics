#!/usr/bin/env bash
# Install Docker, pull the repeat-masking and gene-prediction containers, and download
# the OrthoDB v12 Arthropoda protein set used as evidence for gene prediction.
# Run once on the VM:  bash scripts/00_setup/install_annotation_tools.sh
set -euo pipefail

ORTHODB_DIR="${ORTHODB_DIR:-${HOME}/data/orthodb}"
ORTHODB_URL="https://bioinf.uni-greifswald.de/bioinf/partitioned_odb12/Arthropoda.fa.gz"
ORTHODB_MD5="02c9a5cc4efb9d4d5957f6bd2017a03a"

if ! command -v docker >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y docker.io
fi
sudo systemctl enable --now docker

sudo docker pull dfam/tetools:latest
sudo docker pull teambraker/braker3:latest

mkdir -p "${ORTHODB_DIR}"
cd "${ORTHODB_DIR}"
if [ ! -s Arthropoda.fa ]; then
    wget -c "${ORTHODB_URL}" -O Arthropoda.fa.gz
    echo "${ORTHODB_MD5}  Arthropoda.fa.gz" | md5sum -c -
    gunzip Arthropoda.fa.gz
fi

{
    date +%F
    sudo docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep -E 'tetools|braker3'
    echo "OrthoDB v12 Arthropoda partition, md5 of the gz file ${ORTHODB_MD5}"
} > "${ORTHODB_DIR}/annotation_tool_versions.txt"

echo "Done. Protein evidence: ${ORTHODB_DIR}/Arthropoda.fa"
