#!/usr/bin/env bash
# =============================================================================
# run_annotation_pipeline.sh
#
# Orquestrador do pipeline de anotação de genomas bacterianos (isolados):
#   Prodigal (isolado) + RGI CARD  ->  resistome/
#   geNomad (padrão)
#   ABRicate (bancos não-resistência: vfdb, plasmidfinder, ecoh, ecoli_vf)
#
# Cada etapa é um script independente (ver bioinformatics/tools.md) e cada
# um já pula genoma/etapa já processado -- então re-rodar esse orquestrador
# depois de uma falha no meio de ~7000 genomas é seguro, só o que faltou
# roda de novo.
#
# arg_ranker FICA DE FORA por enquanto (rodar à parte, ver tools.md).
#
# Uso:
#   ./run_annotation_pipeline.sh <genomes_dir> <genomad_db> [JOBS]
#   Exemplo:
#     ./run_annotation_pipeline.sh genomes/ /dados/genomad_db 64
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -lt 2 ]; then
    log_error "Uso: $0 <genomes_dir> <genomad_db> [JOBS]"
    exit 1
fi

GENOMES_DIR="$1"
GENOMAD_DB="$2"
JOBS="${3:-64}"
GENOMAD_JOBS=16
GENOMAD_THREADS_PER_JOB=$((JOBS / GENOMAD_JOBS > 0 ? JOBS / GENOMAD_JOBS : 1))

log "===== 1/3: Prodigal (isolado) + RGI CARD ====="
"${SCRIPT_DIR}/run_prodigal_rgi_isolates.sh" "$GENOMES_DIR" "$JOBS"

log "===== 2/3: geNomad ====="
"${SCRIPT_DIR}/run_genomad.sh" "$GENOMES_DIR" "genomad_out" "$GENOMAD_DB" "$GENOMAD_JOBS" "$GENOMAD_THREADS_PER_JOB"

log "===== 3/3: ABRicate ====="
"${SCRIPT_DIR}/../amr/run_abricate.sh" "$GENOMES_DIR" "$JOBS"

log "===== Pipeline de anotação finalizado ====="
log "resistome/    -> entrada pronta pro 'argos update'"
log "genomad_out/  -> classificação de plasmídeo/vírus por contig"
log "abricate_out/ -> virulência/plasmídeos (bancos não-resistência)"
