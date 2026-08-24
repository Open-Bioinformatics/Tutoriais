#!/usr/bin/env python3
"""
download_genomes.py

Baixa genomas via NCBI `datasets` a partir de uma lista de accessions.
Pula automaticamente qualquer ID cujo .fna já exista (não vazio) — permite
retomar downloads grandes (ex: milhares de isolados) sem redownload total.

Uso:
    python3 download_genomes.py genome_ids.txt [-o fasta_files]

O arquivo de IDs deve conter um accession por linha (ex: GCA_000793345.1).

Ferramenta: NCBI datasets (testado com datasets v18.16.0)
https://github.com/ncbi/datasets
"""

import argparse
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("file", type=str, help="Arquivo com os IDs de genoma a baixar")
parser.add_argument("-o", "--out_dir", type=str, default="fasta_files",
                     help="Pasta de saída (default: fasta_files)")
args = parser.parse_args()

file = Path(args.file).absolute()
out_dir = Path(args.out_dir)
out_dir.mkdir(exist_ok=True)

print(f"Reading genome IDs from {file}")

with file.open("r") as f:
    genome_ids = [line.strip() for line in f if line.strip()]

print(f"Found {len(genome_ids)} genome IDs to download.")

skipped, baixados, falhas = 0, 0, []

for genome_id in genome_ids:
    out_path = out_dir / f"{genome_id}.fna"

    # --- skip se já baixado com sucesso ---
    if out_path.exists() and out_path.stat().st_size > 0:
        print(f"[SKIP] {genome_id} já existe em {out_path}")
        skipped += 1
        continue

    print(f"[RUN] Downloading genome with ID: {genome_id}")
    command = f"datasets download genome accession {genome_id} --filename {out_path}".split()
    try:
        subprocess.run(command, check=True)
        print(f"  -> Salvo em {out_path}")
        baixados += 1
    except subprocess.CalledProcessError:
        print(f"  -> [ERRO] Falha ao baixar {genome_id}")
        falhas.append(genome_id)
    print()

print("===== RESUMO =====")
print(f"Baixados agora: {baixados} | Já existiam (skip): {skipped} | Falhas: {len(falhas)}")
if falhas:
    print("IDs que falharam:")
    for gid in falhas:
        print(f"  - {gid}")
