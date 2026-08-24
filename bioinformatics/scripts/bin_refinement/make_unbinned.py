#!/usr/bin/env python3
"""
make_unbinned.py

Para cada scaffolds.fasta, identifica quais contigs NÃO foram incluídos em
nenhum bin refinado (MAGScoT) e salva esses contigs "soltos" como um
pseudo-bin (<amostra>_unbinned.fasta). Isso permite que o resistoma desses
contigs também entre na entrada do ARGOS, mesmo sem taxonomia associada.

Pula a amostra se o arquivo unbinned já existir.

Uso:
    python make_unbinned.py <pasta_com_refined_mags> <pasta_com_scaffolds>
"""

import argparse
from pathlib import Path
from Bio import SeqIO

parser = argparse.ArgumentParser()
parser.add_argument("mags", type=str, help="Pasta com os fastas dos bins refinados (refined_mags)")
parser.add_argument("scaffolds", type=str, help="Pasta com os scaffolds.fasta de cada amostra")
args = parser.parse_args()

mags = Path(args.mags)
scaffolds = Path(args.scaffolds)

output_folder = Path("unbinned_contigs")
output_folder.mkdir(exist_ok=True)

print(f"MAGs folder: {mags}")
print(f"Scaffolds folder: {scaffolds}")
print(f"Unbinned contigs will be saved in: {output_folder}")

for scaffold in scaffolds.glob("*.fasta"):
    sample_name = scaffold.stem.split("_")[0]
    output_path = output_folder / f"{sample_name}_unbinned.fasta"

    # --- skip se já processado ---
    if output_path.exists() and output_path.stat().st_size > 0:
        print(f"[SKIP] {sample_name} já tem unbinned extraído em {output_path}")
        continue

    dict_id_contigs = SeqIO.to_dict(SeqIO.parse(scaffold, "fasta"))
    print(f"Current sample {sample_name}")

    binned_ids = set()
    bins = []

    for mag in mags.glob("*.fasta"):
        if mag.stem.startswith(f"{sample_name}_bin"):
            bins.append(mag.stem)
            for record in SeqIO.parse(mag, "fasta"):
                binned_ids.add(record.id)

    if len(bins) == 0:
        print("Current sample has no bins.")
    else:
        print(f"Collected all contig ids from {len(bins)} bins: {bins}")

    unbinned_ids = set(dict_id_contigs.keys()) - binned_ids
    unbinned_records = [dict_id_contigs[uid] for uid in unbinned_ids]
    SeqIO.write(unbinned_records, output_path, "fasta")
    print(f"Wrote {len(unbinned_records)} unbinned contigs to {output_path}")
    print()
