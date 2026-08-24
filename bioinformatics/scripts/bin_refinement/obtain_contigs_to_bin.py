#!/usr/bin/env python3
"""
obtain_contigs_to_bin.py

Gera o arquivo <amostra>.contigs_to_bin.tsv exigido pelo MAGScoT, a partir
dos bins brutos de três binners: ComeBin, MetaDecoder e MetaBAT2.

Formato de saída (sem header):
    BIN<TAB>CONTIG<TAB>BINNER

Uso:
    python obtain_contigs_to_bin.py <pasta_da_amostra>
"""

import argparse
from pathlib import Path
from Bio import SeqIO

# Cores ANSI para o log no terminal (uma cor por binner)
class Cor:
    AZUL = "\033[94m"
    VERDE = "\033[92m"
    AMARELO = "\033[93m"
    RESET = "\033[0m"


CORES_POR_BINNER = {
    "comebin": Cor.AZUL,
    "metadecoder": Cor.VERDE,
    "metabat2": Cor.AMARELO,
}

parser = argparse.ArgumentParser()
parser.add_argument("amostra", type=str, help="Sample folder")
args = parser.parse_args()
amostra = Path(args.amostra)

### Variáveis
# Caminhos dos binners
comebin_folder = amostra / "comebin_out" / "comebin_res" / "comebin_res_bins"
metadecoder_folder = amostra / "metadecoder_out"
metabat2_base = amostra

metabat2_folders = list(metabat2_base.glob("scaffolds.fasta.gz.metabat-bins*"))

output_folder = amostra / "magscot_out"
output_file = output_folder / f"{amostra.name}.contigs_to_bin.tsv"
output_folder.mkdir(exist_ok=True)

# --- skip se já foi gerado ---
if output_file.exists() and output_file.stat().st_size > 0:
    print(f"[SKIP] {output_file} já existe.")
    raise SystemExit(0)

if len(metabat2_folders) == 0:
    print("[WARN] MetaBAT2 folder not found")
    metabat2_bins = []
    metabat2_folder = "N/A"
else:
    metabat2_folder = metabat2_folders[0]
    metabat2_bins = list(metabat2_folder.glob("bin.*.fa"))

# Listando arquivos fasta
comebin_bins = list(comebin_folder.glob("*.fa")) + list(comebin_folder.glob("*.fna"))
metadecoder_bins = list(metadecoder_folder.glob("*.fasta"))

print("Sample:", amostra)
print("Binner, Path, n_MAGs")
print(f"ComeBin, {comebin_folder}, {len(comebin_bins)}")
print(f"MetaDecoder, {metadecoder_folder}, {len(metadecoder_bins)}")
print(f"MetaBAT2, {metabat2_folder}, {len(metabat2_bins)}")
print("")

binners = {
    "comebin": comebin_bins,
    "metadecoder": metadecoder_bins,
    "metabat2": metabat2_bins,
}

with open(output_file, "w") as out:
    for binner_name, mags in binners.items():
        cor = CORES_POR_BINNER.get(binner_name, "")

        for mag in mags:
            bin_name = mag.stem
            n_contigs = 0

            for record in SeqIO.parse(mag, "fasta"):
                node = record.id
                n_contigs += 1
                out.write(f"{bin_name}\t{node}\t{binner_name}\n")

            print(f"{cor}[{binner_name}] {bin_name}: {n_contigs} contigs{Cor.RESET}")

print(f"\nResultado salvo em: {output_file}")
