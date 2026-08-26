#!/usr/bin/env bash
# =============================================================================
# run_prodigal_rgi_isolates.sh
#
# Prodigal (modo ISOLADO, sem -p meta -- assume genoma completo de uma
# espécie só, diferente de scripts/annotation/run_prodigal_rgi.sh que é pra
# MAGs) + RGI CARD, prontos pra virar entrada do ArgosProject (`argos update`).
#
# Paralelizado ENTRE genomas via GNU parallel (não dentro de um genoma --
# Prodigal e RGI são rápidos por genoma; o ganho em escala vem de rodar
# muitos genomas ao mesmo tempo). Cada worker roda 1 genoma por vez, RGI com
# -n 1 (1 thread), então JOBS simultâneos ~= núcleos disponíveis.
#
# Pula (skip) genoma já anotado/processado -- seguro re-rodar em cima de uma
# pasta parcialmente processada (útil rodando em ~7000 genomas).
#
# Ferramentas: Prodigal + RGI/CARD + GNU parallel
# https://github.com/hyattpd/Prodigal
# https://github.com/arpcard/rgi
# https://www.gnu.org/software/parallel/
#
# Uso:
#   ./run_prodigal_rgi_isolates.sh [genomes_dir] [JOBS]
#   (defaults: genomes_dir=genomes, JOBS=64)
#
# Requer: genomes_dir/*.fna (ou .fasta -- ajuste o glob abaixo se precisar)
# =============================================================================

set -uo pipefail   # sem -e: uma falha num genoma não pode matar o parallel inteiro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

GENOMES_DIR="${1:-genomes}"
JOBS="${2:-64}"
RGI_THREADS=1

PRODIGAL_DIR="prodigal_out"
RGI_DIR="rgi_out"
RESISTOME_DIR="resistome"
LOG_DIR="logs"

mkdir -p "$PRODIGAL_DIR" "$RGI_DIR" "$RESISTOME_DIR" "$LOG_DIR"

if ! command -v parallel &> /dev/null; then
    log_error "GNU parallel não encontrado. Instale com: conda install -c conda-forge parallel"
    exit 1
fi

# --- Função que processa 1 genoma (Prodigal -p single + RGI + resistome) ---
process_genome() {
    local genome="$1"
    local base
    base=$(basename "$genome")
    base="${base%.*}"

    local faa="${PRODIGAL_DIR}/${base}.faa"
    local ffn="${PRODIGAL_DIR}/${base}.ffn"
    local gff="${PRODIGAL_DIR}/${base}.gff"
    local rgi_txt="${RGI_DIR}/${base}/${base}_rgi.txt"

    if ! is_valid_fasta "$genome"; then
        log_error "$genome não é um fasta válido ou está vazio. Pulando $base."
        return 1
    fi

    # --- Prodigal, SEM -p meta (modo isolado -- genoma de espécie única) ---
    if is_valid_output "$faa"; then
        log "[SKIP] Prodigal já feito para $base."
    else
        log "[RUN] Prodigal (modo isolado) para $base..."
        prodigal -i "$genome" -a "$faa" -d "$ffn" -o "$gff" -f gff -q
    fi

    if ! is_valid_output "$faa"; then
        log_error "$faa não foi gerado. Pulando RGI para $base."
        return 1
    fi

    # --- RGI CARD ---
    if is_valid_output "$rgi_txt"; then
        log "[SKIP] RGI já feito para $base."
    else
        log "[RUN] RGI para $base..."
        mkdir -p "${RGI_DIR}/${base}"
        rgi main -i "$faa" -o "${RGI_DIR}/${base}/${base}_rgi" -t protein -n "$RGI_THREADS" --clean --local
    fi

    # --- Copiar pro resistome/ (entrada do ARGOS) ---
    if is_valid_output "$rgi_txt"; then
        cp "$rgi_txt" "${RESISTOME_DIR}/${base}_rgi.txt"
    else
        log_error "RGI não gerou saída válida para $base."
        return 1
    fi

    return 0
}
export -f process_genome
export PRODIGAL_DIR RGI_DIR RESISTOME_DIR RGI_THREADS
export -f log log_error is_valid_output is_valid_fasta

# --- Lista de genomas a processar ---
shopt -s nullglob
genomes=("$GENOMES_DIR"/*.fna "$GENOMES_DIR"/*.fasta)
shopt -u nullglob

if [ ${#genomes[@]} -eq 0 ]; then
    log_error "Nenhum genoma (.fna/.fasta) encontrado em $GENOMES_DIR"
    exit 1
fi

log "Total de genomas: ${#genomes[@]} | JOBS simultâneos: $JOBS | RGI threads/job: $RGI_THREADS"

VERSION_LOG="${LOG_DIR}/tool_versions.txt"
: > "$VERSION_LOG"
log_tool_version "Prodigal" prodigal -v
log_tool_version "RGI" rgi main --version

# --- Roda todos os genomas em paralelo, um log por genoma em logs/ ---
printf '%s\n' "${genomes[@]}" | \
    parallel -j "$JOBS" --joblog "${LOG_DIR}/prodigal_rgi_isolates.joblog" \
        'process_genome {} > logs/{/.}.log 2>&1'

# --- Resumo (a partir do joblog do parallel: coluna 7 = exitval) ---
n_total=$(($(wc -l < "${LOG_DIR}/prodigal_rgi_isolates.joblog") - 1))
n_falha=$(awk 'NR>1 && $7!=0' "${LOG_DIR}/prodigal_rgi_isolates.joblog" | wc -l)
n_ok=$((n_total - n_falha))

log "===== RESUMO ====="
log "Total: $n_total | OK: $n_ok | Falhas: $n_falha"
if [ "$n_falha" -gt 0 ]; then
    log_warn "Ver ${LOG_DIR}/prodigal_rgi_isolates.joblog (coluna Exitval != 0) e os logs/<genoma>.log individuais."
fi
