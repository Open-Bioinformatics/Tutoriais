#!/usr/bin/env bash
# =============================================================================
# run_prokka.sh
#
# Anota todos os genomas .fna de uma pasta com Prokka. Pula genomas já
# anotados (detecta pelo .faa de saída) e valida o fasta de entrada antes
# de rodar.
#
# Ferramenta: Prokka (testado com v1.14.6)
# https://github.com/tseemann/prokka
# conda: prokka146
#
# Uso:
#   ./run_prokka.sh [genomes_dir] [annotations_dir]
#   (defaults: genomes_dir=genomes, annotations_dir=prokka_annotations)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

genomes_dir="${1:-genomes}"
annotations_dir="${2:-prokka_annotations}"

mkdir -p "$annotations_dir"

for file in "$genomes_dir"/*.fna; do
    base=$(basename "$file" .fna)
    outdir="${annotations_dir}/${base}"
    faa_file="${outdir}/${base}.faa"

    log "== Processando: $base =="

    if ! is_valid_fasta "$file"; then
        log_warn "$file não é um fasta válido ou está vazio. Pulando."
        continue
    fi

    if is_valid_output "$faa_file"; then
        log "[SKIP] Já anotado: $base"
        continue
    fi

    if [[ -d "$outdir" ]]; then
        log_warn "Output parcial encontrado para $base -> removendo e re-rodando"
        rm -rf "$outdir"
    fi

    log "[RUN] Anotando $base com Prokka..."
    prokka --outdir "$outdir" \
           --prefix "$base" \
           --cpus 32 \
           --kingdom Bacteria \
           "$file"
done

log "Prokka finalizado."
