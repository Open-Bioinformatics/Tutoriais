#!/usr/bin/env python3
"""
group_resistome.py

Agrega todas as tabelas de resistoma (*_rgi.txt, saída do RGI) de uma pasta
em um único CSV, adicionando uma coluna "Assembly" com o accession extraído
do nome do arquivo.

Uso:
    python group_resistome.py <pasta_com_rgi_txt> [-o resistoma_total.csv]

Antes esse script existia duplicado (uma cópia por projeto: pr_genomes/ e
all_isolates/), mudando só o nome do CSV de saída hardcoded no código.
Agora o nome de saída é um argumento (-o), então um script só serve para
qualquer projeto.
"""

from pathlib import Path
import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("input_dir", type=str,
                     help="Diretório de entrada contendo os arquivos de resistoma (*_rgi.txt)")
parser.add_argument("-o", "--output", type=str, default="resistoma_total.csv",
                     help="Nome do CSV de saída (default: resistoma_total.csv)")
args = parser.parse_args()

if not Path(args.input_dir).is_dir():
    print(f"O diretório {args.input_dir} não existe ou não é um diretório válido.")
    raise SystemExit(1)

resistoma_total = pd.DataFrame()

for file in Path(args.input_dir).iterdir():
    if file.is_file() and file.suffix == ".txt":
        print(f"Lendo arquivo: {file.name}")
        # Extrai o Assembly ID (ex: GCA_000793345.1_AZPAE15064_genomic -> GCA_000793345.1)
        partes = file.name.split("_")
        assembly_regex = partes[0] + "_" + partes[1]
        print(f"Assembly extraído: {assembly_regex}")

        resistoma = pd.read_csv(file, sep="\t", header=0)
        resistoma["Assembly"] = assembly_regex
        resistoma_total = pd.concat([resistoma_total, resistoma], ignore_index=True)

resistoma_total.to_csv(args.output, index=False)
print(f"Resistoma total salvo em '{args.output}'")
