#!/usr/bin/env python3
"""
extract_mags.py

Gera um arquivo fasta para cada bin refinado pelo MAGScoT.
Pula a amostra se a pasta refined_mags/ já tiver arquivos.

Uso:
    python extract_mags.py <pasta_da_amostra>
"""

import argparse
from pathlib import Path
from Bio import SeqIO
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("amostra", type=str, help="Sample folder")
args = parser.parse_args()
amostra = Path(args.amostra)

output_folder = amostra / "refined_mags"
output_folder.mkdir(exist_ok=True)

# --- skip se já foram extraídos bins pra essa amostra ---
ja_existentes = list(output_folder.glob(f"{amostra.name}_bin_*.fasta"))
if ja_existentes:
    print(f"[SKIP] {amostra} já tem {len(ja_existentes)} bin(s) extraído(s) em {output_folder}")
    raise SystemExit(0)

# Dict contendo o contig e a sequência do FASTA original
fasta_original = amostra / "metaspades_out" / "scaffolds.fasta"
contigs_originais = SeqIO.to_dict(SeqIO.parse(fasta_original, "fasta"))

# Lendo arquivo de mapeamento
contig_mapping = amostra / "magscot_out" / "MAGScoT.refined.contig_to_bin.out"
mapping = pd.read_csv(contig_mapping, sep="\t")

# Listando o número de bins a serem criados
bins = sorted(mapping["binnew"].unique())
print(f"{len(bins)} bins encontrados para a amostra {amostra}.")

for i, bin_name in enumerate(bins, start=1):
    output_file = output_folder / f"{amostra.name}_bin_{i}.fasta"
    contigs_do_bin_i = mapping.loc[mapping["binnew"] == bin_name]["contig"]

    print(f"{output_file}, {len(contigs_do_bin_i)} contigs")

    with open(output_file, "w") as out:
        for contig in contigs_do_bin_i:
            if contig not in contigs_originais:
                print(f"AVISO: contig não encontrado em {fasta_original}")
                continue
            record = contigs_originais[contig]
            out.write(f">{record.id}\n")
            out.write(f"{record.seq}\n")

print(f"\nBins salvos em: {output_folder}")
