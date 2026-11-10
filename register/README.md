# Register

## discovery_register.tsv

One row per analysis. A row is added when the analysis is planned and completed when
the result is known. Rows are never deleted.

| Column | Entry |
|---|---|
| ID | D001, D002, ... in order of entry |
| Date | YYYY-MM-DD the analysis was run |
| Phase | 1 to 4 |
| Module | Genome audit, orthology, species tree, gene-family change, selection, convergence, synteny, protein domains, transposable elements, gene-tree discordance, ancestral states |
| Question tested | One sentence |
| Species / dataset | Species set and the upstream run it used |
| Tool and version | As installed on the VM |
| Parameters / model | Exact options, or the script name and commit |
| Raw result | Before correction |
| Corrected p / FDR | After correction, with the number of tests |
| Status | Planned, Exploratory, Negative, Inconclusive, Validated, Rejected, Audit |
| Validation done | Which Phase 4 checks have been applied |
| Decision | Follow up, hold, drop |
| Notes / file location | Bucket path of the output |

### Status

- **Planned**: written in the register, not yet run.
- **Exploratory**: a pattern was seen in the screen; not yet validated.
- **Negative**: the analysis ran properly and found nothing.
- **Inconclusive**: the analysis could not answer the question (sampling, data quality, failed model).
- **Validated**: passed every Phase 4 check listed in the protocol.
- **Rejected**: an exploratory pattern that failed validation.
- **Audit**: a data-collection or quality step that tests no biological question.

## genome_audit.tsv

One row per batch 1 assembly, written by `scripts/01_genome_audit/06_fill_audit_table.py`. Assembly values are taken from
NCBI, BUSCO values from our own runs with arachnida_odb10, and feeding type from
McMurtry et al. (2013) for Phytoseiidae.
