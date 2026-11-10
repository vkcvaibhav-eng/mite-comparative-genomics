#!/usr/bin/env python3
"""Keep the longest protein per gene from a BRAKER protein file.

Usage:  python scripts/02_foundation/03_longest_isoform.py braker.aa out.faa

BRAKER names transcripts GENE.tN (for example g12.t1, g12.t2). Proteins shorter than
50 amino acids or with an internal stop are dropped. Prints: genes kept, proteins read,
proteins dropped.
"""
import re
import sys

MIN_LEN = 50


def read_fasta(path):
    name, seq = None, []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line.startswith(">"):
                if name is not None:
                    yield name, "".join(seq)
                name, seq = line[1:].split()[0], []
            elif line:
                seq.append(line)
    if name is not None:
        yield name, "".join(seq)


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    best, n_read, n_drop = {}, 0, 0
    for name, seq in read_fasta(sys.argv[1]):
        n_read += 1
        seq = seq.rstrip("*")
        if len(seq) < MIN_LEN or "*" in seq:
            n_drop += 1
            continue
        gene = re.sub(r"\.t\d+$", "", name)
        if gene not in best or len(seq) > len(best[gene][1]):
            best[gene] = (name, seq)
    with open(sys.argv[2], "w") as out:
        for gene in sorted(best):
            name, seq = best[gene]
            out.write(f">{name}\n")
            for i in range(0, len(seq), 60):
                out.write(seq[i:i + 60] + "\n")
    print(f"{len(best)}\t{n_read}\t{n_drop}")


if __name__ == "__main__":
    main()
