#!/usr/bin/env python3
"""
bin2catcolour.py

Gera o TSV "seq<TAB>categoria" usado pelo Blobtools (--catcolour) para
colorir os contigs de um blobplot de acordo com o bin a que pertencem.
Espera ser rodado numa pasta contendo os fastas dos bins (*.fna).

Uso:
    python bin2catcolour.py [-o blobplot_bin_colour.tsv]
"""

import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--output", type=str, default="blobplot_bin_colour.tsv",
                     help="Nome do TSV de saída (default: blobplot_bin_colour.tsv)")
args = parser.parse_args()

output_path = Path(args.output)

# --- skip se já existe ---
if output_path.exists() and output_path.stat().st_size > 0:
    print(f"[SKIP] {output_path} já existe.")
    raise SystemExit(0)

with open(output_path, "w") as output_file:
    for file in Path().iterdir():
        if file.suffix == ".fna":
            bin_name = file.stem
            print(f"Processando {file}...")

            with open(file) as f:
                for line in f:
                    if line.startswith(">"):
                        contig = line.strip()[1:]
                        output_file.write(f"{contig}\tbin_{bin_name}\n")

print(f"Processamento concluído. Resultado salvo em {output_path}")
