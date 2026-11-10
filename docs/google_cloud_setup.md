# Google Cloud setup

Commands are run in Cloud Shell (the `>_` icon at the top of the Google Cloud console).
Replace the names in capitals.

## 1. Project and billing

1. Create a project in the console, for example `mite-genomics`.
2. Link a billing account to it.
3. Billing > Budgets and alerts > create a budget with email alerts at 50 %, 90 % and
   100 %.

```bash
gcloud config set project PROJECT_ID
gcloud services enable compute.googleapis.com storage.googleapis.com
```

## 2. Storage bucket

Bucket names are global, so the name has to be unique.

```bash
gcloud storage buckets create gs://BUCKET_NAME \
    --location=asia-south1 \
    --uniform-bucket-level-access
```

Layout used by the scripts and the register:

```
gs://BUCKET_NAME/genomes/       downloaded assemblies and annotations
gs://BUCKET_NAME/busco/         BUSCO output
gs://BUCKET_NAME/orthofinder/   orthology runs
gs://BUCKET_NAME/trees/         alignments and trees
gs://BUCKET_NAME/discovery/     one folder per module and run
```

## 3. Virtual machine

8 vCPU, 32 GB RAM, 200 GB disk, Ubuntu 24.04, in Mumbai.

```bash
gcloud compute instances create mite-genomics-vm \
    --zone=asia-south1-c \
    --machine-type=e2-standard-8 \
    --boot-disk-size=200GB \
    --boot-disk-type=pd-balanced \
    --image-family=ubuntu-2404-lts-amd64 \
    --image-project=ubuntu-os-cloud \
    --scopes=storage-rw
```

## 4. Daily use

```bash
# start, connect, stop
gcloud compute instances start mite-genomics-vm --zone=asia-south1-c
gcloud compute ssh mite-genomics-vm --zone=asia-south1-c
gcloud compute instances stop mite-genomics-vm --zone=asia-south1-c
```

The VM is billed for every hour it is running, so it is stopped at the end of each
session. The disk is billed while it exists, whether the VM is running or not.

Long jobs are run inside `tmux` so they continue after the SSH window is closed:

```bash
tmux new -s audit        # start a session
# run the job, then press Ctrl-b followed by d to detach
tmux attach -t audit     # come back to it
```

## 5. First session on the VM

```bash
git clone https://github.com/vkcvaibhav-eng/mite-comparative-genomics.git
cd mite-comparative-genomics
bash scripts/00_setup/install_tools.sh
# open a new shell
conda activate mite-audit

bash scripts/01_genome_audit/01_list_public_genomes.sh
# choose accessions from results_summaries/genome_audit/, save them in accessions.txt
bash scripts/01_genome_audit/02_download_genomes.sh accessions.txt gs://BUCKET_NAME
bash scripts/01_genome_audit/03_run_busco.sh 8
python scripts/01_genome_audit/04_summarise_busco.py ~/data/busco
gcloud storage rsync --recursive ~/data/busco gs://BUCKET_NAME/busco
```

## 6. Resizing later

The machine type can be changed while the VM is stopped:

```bash
gcloud compute instances set-machine-type mite-genomics-vm \
    --zone=asia-south1-c --machine-type=e2-standard-16
```
