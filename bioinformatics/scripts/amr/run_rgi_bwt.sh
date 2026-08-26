#!/usr/bin/env bash
# =============================================================================
# run_rgi_bwt.sh
#
# Mapeia reads (fastq) diretamente contra o CARD + WildCARD usando KMA,
# via `rgi bwt` -- alternativa ao Prodigal+RGI quando você quer resistoma
# direto das reads, sem montagem/anotação de genes.
#
# Ferramenta: RGI (modo bwt/kma) + CARD/WildCARD
# https://github.com/arpcard/rgi/blob/master/docs/rgi_bwt.rst
# (testado com RGI v6.0.5, card_canonical 4.0.1, card_variants 4.0.2)
#
# Uso:
#   ./run_rgi_bwt.sh <read_1.fastq> <read_2.fastq> <outdir> [sample_name]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -lt 3 ]; then
    log_error "Uso: $0 <read_1.fastq> <read_2.fastq> <outdir> [sample_name]"
    exit 1
fi

R1="$1"
R2="$2"
OUTDIR="$3"
SAMPLE_NAME="${4:-$(basename "$R1" | sed 's/_1.*//')}"

mkdir -p "$OUTDIR"

output_prefix="${OUTDIR}/${SAMPLE_NAME}_kma_mapping_out"

if is_valid_output "${output_prefix}.gene_mapping_data.txt"; then
    log "[SKIP] $SAMPLE_NAME já mapeado (${output_prefix}.gene_mapping_data.txt existe)"
    exit 0
fi

log "[RUN] Mapeando $SAMPLE_NAME contra CARD/WildCARD via KMA..."

rgi bwt \
    -1 "$R1" \
    -2 "$R2" \
    -a kma \
    -n 32 \
    -o "$output_prefix" \
    --include_wildcard \
    --include_other_models

log "$SAMPLE_NAME finalizado. Resultado: ${output_prefix}.gene_mapping_data.txt"
