#!/usr/bin/env bash
# Download genome, protein, CDS and GFF3 files for the accessions chosen from the
# NCBI listing, then copy them to the Cloud Storage bucket.
# Usage:  bash scripts/01_genome_audit/02_download_genomes.sh accessions.txt gs://BUCKET_NAME
#   accessions.txt : one assembly accession per line (GCA_... or GCF_...)
set -euo pipefail

ACCESSIONS="$(realpath "${1:?Give the accession list file}")"
BUCKET="${2:?Give the bucket, e.g. gs://my-bucket}"
DATA_DIR="${DATA_DIR:-${HOME}/data/genomes}"

mkdir -p "${DATA_DIR}"
cd "${DATA_DIR}"

datasets download genome accession --inputfile "${ACCESSIONS}" \
    --include genome,protein,cds,gff3 \
    --dehydrated --filename ncbi_dataset.zip

unzip -o ncbi_dataset.zip -d .
datasets rehydrate --directory .

# What was actually delivered for each accession (annotation is absent for many)
{
    printf "accession\tgenome\tprotein\tcds\tgff3\n"
    for d in ncbi_dataset/data/GC*; do
        acc="$(basename "${d}")"
        g=no; p=no; c=no; f=no
        ls "${d}"/*_genomic.fna >/dev/null 2>&1 && g=yes
        [ -f "${d}/protein.faa" ] && p=yes
        [ -f "${d}/cds_from_genomic.fna" ] && c=yes
        [ -f "${d}/genomic.gff" ] && f=yes
        printf "%s\t%s\t%s\t%s\t%s\n" "${acc}" "${g}" "${p}" "${c}" "${f}"
    done
} > download_manifest.tsv

gcloud storage rsync --recursive ncbi_dataset "${BUCKET}/genomes/ncbi_dataset"
gcloud storage cp download_manifest.tsv "${BUCKET}/genomes/download_manifest.tsv"

echo "Finished. Manifest: ${DATA_DIR}/download_manifest.tsv"
