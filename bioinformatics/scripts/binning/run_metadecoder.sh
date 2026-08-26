#!/usr/bin/env bash
# =============================================================================
# run_metadecoder.sh
#
# Roda o MetaDecoder numa amostra já montada e mapeada.
# Pula a amostra se a etapa de clustering já tiver sido concluída.
#
# Ferramenta: MetaDecoder (testado com v1.2.2)
# https://github.com/liu-congcong/MetaDecoder
#
# Uso:
#   ./run_metadecoder.sh <sample_dir>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 1 ]; then
    log_error "Uso: $0 <sample_dir>"
    exit 1
fi

amostra="$1"
outdir="${amostra}metadecoder_out/"

# --- skip se o clustering já foi feito (gera pelo menos um .fasta de bin) ---
if compgen -G "${outdir}METADECODER.*.fasta" > /dev/null; then
    log "[SKIP] ${amostra} já binada pelo MetaDecoder"
    exit 0
fi

log "Processando a amostra $amostra"
log "Salvando dados intermediários e resultados em $outdir"

mkdir -p "$outdir"

log "Obtendo a cobertura dos contigs"
metadecoder coverage -b "${amostra}mapping/alignment.sorted.bam" -o "${outdir}METADECODER.COVERAGE"

log "Mapeando genes marcadores single-copy na montagem"
metadecoder seed --threads 50 -f "${amostra}metaspades_out/scaffolds.fasta" -o "${outdir}METADECODER.SEED"

log "Clustering"
metadecoder cluster \
    -f "${amostra}metaspades_out/scaffolds.fasta" \
    -c "${outdir}METADECODER.COVERAGE" \
    -s "${outdir}METADECODER.SEED" \
    -o "${outdir}METADECODER"

log "$amostra finalizada"
