#!/usr/bin/env bash
# =============================================================================
# run_genomad.sh
#
# Classifica cada contig como cromossomo/plasmídeo/vírus com geNomad.
# Comando do geNomad continua o padrão (end-to-end, sem flags especiais) --
# só mudou COMO chamamos ele: agora paralelizado ENTRE genomas via GNU
# parallel, pra dar conta de rodar em escala (ex: ~7000 genomas). Cada job
# usa THREADS_PER_JOB threads; JOBS jobs simultâneos, então
# JOBS * THREADS_PER_JOB deve ficar perto do total de núcleos disponíveis.
#
# Pula genomas já processados (detecta pela pasta de output correspondente).
#
# Ferramenta: geNomad + GNU parallel
# https://github.com/apcamargo/genomad
# https://www.gnu.org/software/parallel/
#
# Uso:
#   ./run_genomad.sh <input_dir> <output_dir> <db_path> [JOBS] [THREADS_PER_JOB]
#   (defaults: JOBS=16, THREADS_PER_JOB=4  -> 16*4=64 núcleos)
# =============================================================================

set -uo pipefail   # sem -e: uma falha num genoma não pode matar o parallel inteiro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -lt 3 ]; then
    log_error "Uso: $0 INPUT_DIR OUTPUT_DIR DB [JOBS] [THREADS_PER_JOB]"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
DB="$3"
JOBS="${4:-16}"
THREADS_PER_JOB="${5:-4}"

mkdir -p "$OUTPUT_DIR"

if ! command -v parallel &> /dev/null; then
    log_error "GNU parallel não encontrado. Instale com: conda install -c conda-forge parallel"
    exit 1
fi

process_genome() {
    local genome="$1"
    local outdir="$2"
    local db="$3"
    local threads="$4"
    local base
    base=$(basename "$genome")
    base="${base%.*}"

    if [ -d "${outdir}/${base}" ] && [ -n "$(ls -A "${outdir}/${base}" 2>/dev/null)" ]; then
        log "[SKIP] $base já processado por geNomad"
        return 0
    fi

    log "[RUN] Processando $base..."

    genomad end-to-end \
        --cleanup \
        --threads "$threads" \
        "$genome" \
        "${outdir}/${base}" \
        "$db"

    log "Finished processing $base"
}
export -f process_genome
export -f log

shopt -s nullglob
genomes=("$INPUT_DIR"/*.fasta "$INPUT_DIR"/*.fna)
shopt -u nullglob

if [ ${#genomes[@]} -eq 0 ]; then
    log_error "Nenhum genoma (.fasta/.fna) encontrado em $INPUT_DIR"
    exit 1
fi

log "Total de genomas: ${#genomes[@]} | JOBS simultâneos: $JOBS | threads/job: $THREADS_PER_JOB"

mkdir -p logs
printf '%s\n' "${genomes[@]}" | \
    parallel -j "$JOBS" --joblog logs/genomad.joblog \
        process_genome {} "$OUTPUT_DIR" "$DB" "$THREADS_PER_JOB"

n_total=$(($(wc -l < logs/genomad.joblog) - 1))
n_falha=$(awk 'NR>1 && $7!=0' logs/genomad.joblog | wc -l)
log "===== RESUMO ====="
log "Total: $n_total | OK: $((n_total - n_falha)) | Falhas: $n_falha"
