# Mite comparative genomics

Comparative analysis of public nuclear genomes of phytophagous and predatory mites
(Tetranychidae, Tenuipalpidae, Eriophyidae, Phytoseiidae and other Mesostigmata, with
outgroups), looking for evolutionary and genomic patterns linked to feeding ecology.

The title and the central hypothesis are fixed only after the analyses show which
pattern holds up. The method is fixed in advance; the hypothesis is not.

**Investigator:** V. K. Chaudhari, AINP on Agricultural Acarology, Department of
Entomology, N. M. College of Agriculture, Navsari Agricultural University, Navsari,
Gujarat, India.

## Working rules

1. The pipeline, tools and statistical thresholds are written in
   `protocol/analysis_protocol.md` before any results are seen.
2. Every analysis is logged in `register/discovery_register.tsv`, including negative
   and inconclusive results.
3. Anything found in the screen is exploratory until it passes validation.
4. Exploratory findings are never presented as pre-planned hypotheses.
5. Shared ancestry is accounted for: 15 species are not 15 independent observations.
6. Any change to the protocol after it is frozen goes in `protocol/deviations.md`
   with a date and a reason.

## Phases

| Phase | Work | Output |
|---|---|---|
| 0. Protocol and register | Analysis protocol, discovery register, Google Cloud VM and bucket | Frozen protocol |
| 1. Genome audit | Collect public genomes; assembly level, N50, BUSCO (arachnida_odb10), annotation status; feeding type; count independent feeding-strategy transitions | Final species list |
| 2. Foundation | OrthoFinder, IQ-TREE species tree with concordance factors, InterProScan, eggNOG-mapper | Orthogroups, species tree, annotations |
| 3. Open discovery screen | Gene-family change (CAFE 5), selection (HyPhy), convergence, synteny, protein domains, transposable elements, gene-tree discordance, ancestral feeding states | Ranked outliers |
| 4. Validation | FDR correction, phylogenetic correction, manual re-annotation, re-runs without weak assemblies | Confirmed findings |
| 5. Story and manuscript | Choose the strongest pattern, fix the title, add laboratory evidence if the finding points to a mechanism | Manuscript |

## Repository layout

```
protocol/            analysis protocol, software versions, deviations log
register/            discovery register and genome audit table (TSV)
envs/                conda environment files, one per phase
scripts/
  00_setup/          VM setup and tool installation
  01_genome_audit/   genome listing, download, BUSCO
  02_foundation/     orthology, species tree, functional annotation
  03_discovery/      screening modules
  04_validation/     correction and robustness checks
results_summaries/   small summary tables and figures only
docs/                setup notes
```

## Where the data lives

Genome assemblies, proteomes, alignments, trees and other large or intermediate files
are kept in a Google Cloud Storage bucket, not in this repository. Only scripts, the
protocol, the register and small summary tables are committed here. The `.gitignore`
blocks sequence and alignment formats.

Each register entry records the bucket path of its output, so any result can be traced
from the register to the files.

## Starting on a new VM

```bash
git clone https://github.com/vkcvaibhav-eng/mite-comparative-genomics.git
cd mite-comparative-genomics
bash scripts/00_setup/install_tools.sh
```

Google Cloud setup is described in `docs/google_cloud_setup.md`.

## Status

| Date | Phase | Note |
|---|---|---|
| 2026-11-10 | 0 | Repository created; protocol in draft |
