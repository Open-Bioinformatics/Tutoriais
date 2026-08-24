#!/usr/bin/env bash
# =============================================================================
# run_genomad.sh
#
# Classifica cada contig como cromossomo/plasmídeo/vírus com geNomad.
# Pula genomas já processados (detecta pela pasta de output correspondente).
#
# Ferramenta: geNomad
# https://github.com/apcamargo/genomad
#
# Uso:
#   ./run_genomad.sh <input_dir> <output_dir> <db_path>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 3 ]; then
    log_error "Uso: $0 INPUT_DIR OUTPUT_DIR DB"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
DB="$3"
THREADS=64

mkdir -p "$OUTPUT_DIR"

for genome in "$INPUT_DIR"/*.fasta; do
    base=$(basename "$genome" .fasta)

    if [ -d "${OUTPUT_DIR}/${base}" ] && [ -n "$(ls -A "${OUTPUT_DIR}/${base}" 2>/dev/null)" ]; then
        log "[SKIP] $base já processado por geNomad"
        continue
    fi

    log "[RUN] Processando $base..."

    genomad end-to-end \
        --cleanup \
        --threads "$THREADS" \
        "$genome" \
        "$OUTPUT_DIR/$base" \
        "$DB"

    log "Finished processing $base"
done
