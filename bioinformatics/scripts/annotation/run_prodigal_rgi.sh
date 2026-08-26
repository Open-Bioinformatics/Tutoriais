#!/usr/bin/env bash
# =============================================================================
# run_prodigal_rgi.sh
#
# Pipeline: Prodigal (gene calling) + RGI (anotação de AMR/CARD) para MAGs.
# Entrada:  all_mags/*.fasta  (refined_mags + pseudo-bins unbinned)
# Saída:    prodigal_out/, prodigal_clean/, rgi_out/, resistome/
#
# Cada etapa é pulada se o output já existir e for válido -- é o padrão de
# skip granular reaproveitado pelos outros scripts deste repositório
# (ver lib/checks.sh).
#
# Ferramentas: Prodigal + RGI/CARD
# https://github.com/hyattpd/Prodigal
# https://github.com/arpcard/rgi
#
# Uso:
#   ./run_prodigal_rgi.sh [input_dir]
#   (default: input_dir=all_mags)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

# --- Diretórios ---
INPUT_DIR="${1:-all_mags}"
PRODIGAL_DIR="prodigal_out"
CLEAN_DIR="prodigal_clean"
RGI_DIR="rgi_out"
RESISTOME_DIR="resistome"
LOG_DIR="logs"
VERSION_LOG="${LOG_DIR}/tool_versions.txt"

mkdir -p "$PRODIGAL_DIR" "$CLEAN_DIR" "$RGI_DIR" "$RESISTOME_DIR" "$LOG_DIR"

# --- Registrar versões das ferramentas usadas nesta rodada ---
: > "$VERSION_LOG"
log_tool_version "Prodigal" prodigal -v
log_tool_version "RGI" rgi main --version
log_tool_version "CARD DB (local)" rgi database --version --local
log "Versões registradas em $VERSION_LOG"

TOTAL=0
PRODIGAL_RUN=0
PRODIGAL_SKIP=0
RGI_RUN=0
RGI_SKIP=0
FAILED=()

for genome in "$INPUT_DIR"/*.fasta; do
    TOTAL=$((TOTAL + 1))
    base=$(basename "$genome" .fasta)
    log "== Processando: $base =="

    # --- 1. Validar fasta de entrada ---
    if ! is_valid_fasta "$genome"; then
        log_error "$genome não é um fasta válido ou está vazio. Pulando."
        FAILED+=("$base (fasta de entrada inválido)")
        continue
    fi

    faa="${PRODIGAL_DIR}/${base}.faa"
    ffn="${PRODIGAL_DIR}/${base}.ffn"
    gff="${PRODIGAL_DIR}/${base}.gff"
    gbk="${PRODIGAL_DIR}/${base}.gbk"

    # --- 2. Prodigal: roda só se faltar algum output ou estiver vazio ---
    if is_valid_output "$faa" && is_valid_output "$gff" && is_valid_output "$gbk"; then
        log "[SKIP] Prodigal já feito para $base."
        PRODIGAL_SKIP=$((PRODIGAL_SKIP + 1))
    else
        log "[RUN] Prodigal (faa/ffn/gff) para $base..."
        prodigal -i "$genome" -a "$faa" -d "$ffn" -o "$gff" -f gff -p meta -q
        log "[RUN] Prodigal (gbk, p/ clinker depois) para $base..."
        prodigal -i "$genome" -o "$gbk" -f gbk -p meta -q
        PRODIGAL_RUN=$((PRODIGAL_RUN + 1))
    fi

    if ! is_valid_output "$faa"; then
        log_error "$faa não foi gerado ou está vazio. Pulando RGI para $base."
        FAILED+=("$base (prodigal falhou)")
        continue
    fi

    # --- 3. Limpeza do .faa (remove '*' de stop codon, exigido pelo RGI) ---
    clean_faa="${CLEAN_DIR}/${base}.faa"
    if is_valid_output "$clean_faa"; then
        log "[SKIP] Limpeza já feita para $base."
    else
        log "[RUN] Limpando $faa..."
        sed 's/\*$//' "$faa" > "$clean_faa"
    fi

    # --- 4. Validar o arquivo antes do RGI ---
    if ! is_valid_fasta "$clean_faa"; then
        log_error "$clean_faa não é um fasta válido ou está vazio. Pulando RGI para $base."
        FAILED+=("$base (faa limpo inválido)")
        continue
    fi

    # --- 5. RGI: roda só se faltar output ou estiver vazio ---
    rgi_txt="${RGI_DIR}/${base}/${base}_rgi.txt"
    if is_valid_output "$rgi_txt"; then
        log "[SKIP] RGI já feito para $base."
        RGI_SKIP=$((RGI_SKIP + 1))
    else
        log "[RUN] RGI para $base..."
        mkdir -p "${RGI_DIR}/${base}"
        rgi main -i "$clean_faa" -o "${RGI_DIR}/${base}/${base}_rgi" -t protein --clean
        RGI_RUN=$((RGI_RUN + 1))
    fi

    # --- 6. Copiar resultado final pro resistome/ (o que alimenta o ARGOS) ---
    if is_valid_output "$rgi_txt"; then
        cp "$rgi_txt" "${RESISTOME_DIR}/${base}_rgi.txt"
    else
        log_error "RGI não gerou saída válida para $base."
        FAILED+=("$base (rgi falhou)")
    fi
done

log "===== RESUMO ====="
log "Total de genomas processados: $TOTAL"
log "Prodigal executado: $PRODIGAL_RUN | pulado (já existia): $PRODIGAL_SKIP"
log "RGI executado: $RGI_RUN | pulado (já existia): $RGI_SKIP"
log "Falhas: ${#FAILED[@]}"
for f in "${FAILED[@]:-}"; do
    log "  - $f"
done
