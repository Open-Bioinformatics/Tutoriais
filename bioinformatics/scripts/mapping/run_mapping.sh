#!/usr/bin/env bash
# =============================================================================
# run_mapping.sh
#
# Mapeia as reads (QC'd) contra o metagenoma montado (scaffolds.fasta) e gera
# o BAM ordenado + indexado exigido por todos os binners (MetaBAT2,
# MetaDecoder, COMEBin). Pula a amostra se o BAM ordenado já existir.
#
# Ferramentas: Bowtie2 (v2.3.5.1) + Samtools (v1.17)
# https://github.com/BenLangmead/bowtie2
# https://github.com/samtools/samtools
#
# NOTA (histórico): a versão antiga desse script (make_bam_files.sh) tinha um
# bug -- usava a variável indefinida $SINGLE em vez de $singleton no comando
# do bowtie2, o que quebraria o mapeamento single-end. Corrigido aqui.
#
# Uso:
#   ./run_mapping.sh <sample_dir>
#   Exemplo: ./run_mapping.sh Mangrove/VAN1/
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
outdir="${sample_dir}mapping"
metagenoma="${sample_dir}metaspades_out/scaffolds.fasta"
index_prefix="${outdir}/scaffold_index"

# --- skip se o mapeamento já foi feito ---
if is_valid_output "${outdir}/alignment.sorted.bam" && is_valid_output "${outdir}/alignment.sorted.bam.bai"; then
    log "[SKIP] ${sample_dir} já mapeada (${outdir}/alignment.sorted.bam existe)"
    exit 0
fi

R1=$(find "$reads_dir" -name "*1_paired*" | head -n 1)
R2=$(find "$reads_dir" -name "*2_paired*" | head -n 1)
singleton=$(find "$reads_dir" -name "*singleton*" | head -n 1)

log "Processando a amostra $1"
log "R1: $R1"
log "R2: $R2"
log "Singleton: $singleton"
log "Metagenoma: $metagenoma"

mkdir -p "$outdir"

# --- Construindo o index ---
log "Construindo index do $1"
bowtie2-build "$metagenoma" "$index_prefix" --verbose
log "Index do $1 construído"

# --- Mapeando as reads ---
log "Mapeando as reads do $1"
bowtie2 -x "$index_prefix" \
    -1 "$R1" \
    -2 "$R2" \
    -U "$singleton" \
    -S "$outdir/alignment.sam" \
    -p 8 \
    --very-sensitive-local
log "Mapeamento da amostra $1 finalizado"

# --- Convertendo para BAM ---
log "Convertendo SAM -> BAM"
samtools view -@ 8 -bS "$outdir/alignment.sam" > "$outdir/alignment.bam"

log "Ordenando BAM"
samtools sort -@ 8 "$outdir/alignment.bam" -o "$outdir/alignment.sorted.bam"

log "Indexando BAM"
samtools index "$outdir/alignment.sorted.bam"

# --- Limpeza de intermediários grandes (sam e bam não ordenado) ---
rm -f "$outdir/alignment.sam" "$outdir/alignment.bam"

log "Fim do mapeamento de $1"
