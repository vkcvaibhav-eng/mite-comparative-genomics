# Deviations from the protocol

Changes made after a section of `analysis_protocol.md` was frozen.

| Date | Section | Change | Reason | Results already seen at the time? |
|---|---|---|---|---|

## Decisions taken before the freeze, after audit results had been seen

These are not deviations, because no section was frozen yet. They are listed because
each was written after the BUSCO results of 2026-11-10 were known.

| Date | Section | Decision | Reason | Results already seen at the time? |
|---|---|---|---|---|
| 2026-11-10 | 3 | Protein-mode duplication is measured on the one-protein-per-gene set | NCBI protein files hold every isoform; *Varroa destructor* showed 60.4 % duplicated in protein mode and 0.9 % in genome mode | Yes, BUSCO only |
| 2026-11-10 | 3 | Rule for reduced genomes added | All five Eriophyoidea assemblies scored 57.5 to 68.0 % with under 2 % fragmented; the fixed 80 % threshold would have removed the whole lineage | Yes, BUSCO only |
| 2026-11-10 | 3 | Assemblies with 10 % or more genome-mode duplication are kept, marked and removed in a re-test | *Dermanyssus gallinae*, *Amphitetranychus viennensis* and *Panonychus citri* reached the limit; no read data are used in this study to purge haplotypes | Yes, BUSCO only |
| 2026-11-10 | 4 | All assemblies annotated with one pipeline; acceptance rule set before the pilot | 23 of 38 assemblies have no proteins at NCBI, and they include four of the five Phytoseiidae | Yes, BUSCO only; no annotation result seen |
