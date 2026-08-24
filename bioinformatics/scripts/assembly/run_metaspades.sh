#!/usr/bin/env bash
# =============================================================================
# run_metaspades.sh
#
# Roda o metaSPAdes numa amostra de metagenoma, a partir das reads pareadas
# + singletons já processadas pelo QC (fastp) e reparadas (bbtools repair.sh,
# ver tools.md). Pula a amostra se scaffolds.fasta já existir.
#
# Ferramenta: SPAdes [metaSPAdes mode] (testado com v3.13.1)
# https://github.com/ablab/spades
# conda: metaspades
#
# Espera a estrutura:
#   <sample_dir>/reads/*1_paired*.fastq
#   <sample_dir>/reads/*2_paired*.fastq
#   <sample_dir>/reads/*singleton*.fastq
#
# Uso:
#   ./run_metaspades.sh <sample_dir>
#   Exemplo: ./run_metaspades.sh Mangrove/VAN1/
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 1 ]; then
    log_error "Uso: $0 <sample_dir>"
    exit 1
fi

sample_dir="$1"
reads_dir="${sample_dir}reads"
outdir="${sample_dir}metaspades_out"

# --- skip se a amostra já foi montada ---
if is_valid_output "${outdir}/scaffolds.fasta"; then
    log "[SKIP] ${sample_dir} já montada (${outdir}/scaffolds.fasta existe)"
    exit 0
fi

R1=$(find "$reads_dir" -name "*1_paired*" | head -n 1)
R2=$(find "$reads_dir" -name "*2_paired*" | head -n 1)
singleton=$(find "$reads_dir" -name "*singleton*" | head -n 1)

log "Processando a amostra $1"
log "R1: $R1"
log "R2: $R2"
log "Singleton: $singleton"

metaspades.py -1 "$R1" -2 "$R2" -s "$singleton" -o "$outdir" -t 32 -m 300

log "$sample_dir finalizado"
