# Analysis protocol

**Status:** Draft 0.1, 2026-11-10. Not frozen.
**Freeze rule:** Sections 1 to 3 are frozen before the first BUSCO run. Sections 4 to 7
are frozen before OrthoFinder is run on the final species list. After a section is
frozen, changes go in `deviations.md` with a date and a reason.

## 1. Scope

Public nuclear genome assemblies of phytophagous and predatory mites: Tetranychidae,
Tenuipalpidae, Eriophyidae, Phytoseiidae and other Mesostigmata, with outgroups from
other Acari and other Arachnida. No hypothesis about which genes or gene families
differ between feeding types is set in advance. All orthogroups are screened.

## 2. Data collection

- Source: NCBI Genome (GenBank and RefSeq), queried with NCBI Datasets. Genomes
  available only from other archives are added by hand and noted in the audit table.
- Search date and the full list of hits are saved in `results_summaries/genome_audit/`.
- One assembly per species: the RefSeq representative if there is one, otherwise the
  assembly with the highest BUSCO completeness.
- Where NCBI has no annotation, the proteome released by the authors of the genome
  paper is used if it is public. Species with no usable annotation are kept for the
  species tree and repeat analysis only.

## 3. Genome audit and inclusion criteria

Recorded for each assembly: accession, assembly level, total length, contig and
scaffold N50, number of scaffolds, BUSCO scores, annotation source and protein count.

One assembly per species is taken from the NCBI listing in this order: a RefSeq
assembly with NCBI annotation; otherwise a GenBank assembly with submitter annotation
and scaffold N50 of at least 100 kb; otherwise the assembly with the highest scaffold
N50. Assemblies with scaffold N50 below 20 kb are listed but not downloaded.

BUSCO is run with the arachnida_odb10 lineage in genome mode on every assembly and in
protein mode on every annotated proteome. Outgroup assemblies larger than 1 Gb are
checked in protein mode only.

| Use | Criterion |
|---|---|
| Gene-family, selection and domain analyses | BUSCO complete >= 80 % in protein mode, duplicated <= 10 % |
| Species tree only | BUSCO complete 60 to 80 % |
| Excluded | BUSCO complete < 60 %, or evident contamination |
| Synteny | Chromosome-level assemblies only |

An assembly with duplicated BUSCO above 10 % is checked for uncollapsed haplotypes
before a decision is taken.

Feeding type: phytophagous families are scored as phytophagous. Phytoseiidae are
classified as Type I (specialist), Type II (selective), Type III (generalist) or
Type IV (pollen-feeding generalist) following McMurtry et al. (2013). Other
Mesostigmata are scored from the primary literature, with the reference noted.

Independent feeding-strategy transitions are counted on the species tree. Trait
association and convergence tests are run only if the sample has at least three
independent transitions of the type being tested. With fewer, those modules are
recorded as not testable and the reason is logged.

## 4. Foundation

**Proteome preparation.** One protein per gene, the longest isoform. Sequences shorter
than 50 amino acids or with internal stop codons are removed. The number removed per
species is recorded.

**Orthology.** OrthoFinder with DIAMOND searches and the multiple-sequence-alignment
option for gene trees (MAFFT alignment, tree inference as provided by OrthoFinder).

**Species tree.**
- Single-copy orthogroups present in all species; if fewer than 200 remain, orthogroups
  single-copy in at least 80 % of species are added.
- Alignment with MAFFT (L-INS-i), trimming with trimAl (`-automated1`).
- Concatenated maximum-likelihood tree in IQ-TREE with a partition model chosen by
  ModelFinder, 1000 ultrafast bootstrap replicates and 1000 SH-aLRT replicates.
- Gene and site concordance factors on the concatenated tree.
- A coalescent summary tree (ASTRAL) from the individual gene trees as a check on
  topology. Branches that differ between the two trees are treated as unresolved in
  every later test.

**Functional annotation.** InterProScan (Pfam, InterPro, Gene Ontology) and
eggNOG-mapper on every proteome, with the same versions and databases for all species.

**Dating.** An ultrametric tree is needed for CAFE. It is produced by penalised
likelihood or least-squares dating with published calibrations if suitable ones
exist. If not, a relative time tree is used and no absolute dates are reported.

## 5. Discovery screen

Every module is run on all eligible orthogroups. Each run is a row in the discovery
register.

| Module | Method | Fixed settings |
|---|---|---|
| Gene-family expansion and contraction | CAFE 5 | Orthogroups with 100 or more copies in any one species analysed separately; error model fitted to account for annotation error; single lambda first, then feeding-type-specific lambda compared by likelihood |
| Positive selection | HyPhy BUSTED and aBSREL | Codon alignments built from the protein alignments; single-copy orthogroups with at least four species; alignments shorter than 100 codons after trimming excluded; foreground branches defined from the species tree before the tests are run |
| Site-level selection | HyPhy MEME | Only on orthogroups significant in BUSTED or aBSREL |
| Relaxed or intensified selection | HyPhy RELAX | Same foreground and background sets as BUSTED |
| Convergent change | Gene-family size convergence and amino-acid convergence at sites | Only between lineages that changed feeding type independently |
| Synteny and rearrangement | MCScanX or GENESPACE | Chromosome-level assemblies only |
| Protein-domain gain and loss | InterProScan domain architectures | Presence or absence and copy number per species, mapped on the species tree |
| Transposable elements | RepeatModeler and RepeatMasker | Same pipeline and library-building method for every genome; published repeat figures are not mixed with our own |
| Gene-tree discordance | IQ-TREE concordance factors | Orthogroups whose trees conflict with the species tree at well-supported nodes |
| Ancestral feeding states | Maximum-likelihood and stochastic-mapping reconstruction | Run only if the audit shows enough transitions |

## 6. Statistical thresholds

- Multiple testing: Benjamini-Hochberg false discovery rate, applied within each module
  across all tests run in that module. Threshold q < 0.05.
- The number of tests in each module is reported with every result.
- CAFE: family-level p < 0.05 after correction, then branch-level results examined only
  for those families.
- HyPhy BUSTED, aBSREL and RELAX: likelihood-ratio test p-values corrected as above;
  aBSREL branch-level p-values corrected within each gene by the method built into the
  tool, then across genes.
- MEME: p < 0.05 per site, reported as descriptive only.
- Trait associations: phylogenetic generalised least squares or phylogenetic logistic
  regression. Uncorrected correlations across species are not reported as evidence.
- Enrichment of functional categories: Fisher's exact test against the background of
  all tested orthogroups, Benjamini-Hochberg q < 0.05.

## 7. Validation

A pattern is recorded as Validated only if all of these hold:

1. It remains significant after the correction in Section 6.
2. It remains after phylogenetic correction, where the claim is an association with
   feeding type.
3. The gene models behind it have been checked by hand in the top candidates
   (fragmented, fused or missing models ruled out by searching the genome sequence).
4. It is still present when assemblies in the 80 to 90 % BUSCO range are removed.
5. It is still present under an alternative model or tool for the same question.
6. It has been compared with the published genome papers and gene-family studies for
   the species involved, and what is already known is separated from what is new.

A pattern that fails any check is recorded as Rejected, with the check that failed.

## 8. Reporting

- The manuscript states that the study was exploratory and reports the number of
  modules and tests run.
- Negative and inconclusive modules are reported in the supplementary material.
- The register, this protocol and the deviations log are released with the paper.

## 9. Software

Exact versions are written to `software_versions.tsv` from the conda environment
export at the start of each phase and are not changed within a phase.

| Purpose | Tool |
|---|---|
| Genome listing and download | NCBI Datasets command-line tools |
| Completeness | BUSCO, arachnida_odb10 |
| Sequence handling | SeqKit, AGAT |
| Orthology | OrthoFinder, DIAMOND |
| Alignment and trimming | MAFFT, trimAl |
| Phylogeny | IQ-TREE, ASTRAL |
| Functional annotation | InterProScan, eggNOG-mapper |
| Gene-family evolution | CAFE 5 |
| Selection | HyPhy |
| Synteny | MCScanX or GENESPACE |
| Repeats | RepeatModeler, RepeatMasker |
| Statistics and comparative methods | R (ape, phytools, phylolm) |

## Reference

McMurtry, J. A., De Moraes, G. J. and Sourassou, N. F. (2013). Revision of the
lifestyles of phytoseiid mites (Acari: Phytoseiidae) and implications for biological
control strategies. Systematic and Applied Acarology, 18(4), 297-320.
