#!/usr/bin/env bash
# =============================================================================
# lib/checks.sh
#
# Biblioteca de funções compartilhadas por todos os scripts de
# bioinformatics/scripts/. Objetivo: reduzir redundância e permitir que
# qualquer script pule amostras já processadas (reprodutibilidade / re-runs
# seguros depois de uma falha no meio do caminho).
#
# Uso: no topo do script que for usar essas funções:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/../lib/checks.sh"
# =============================================================================

# --- Log colorido com timestamp ---------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log()       { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $*${NC}"; }
log_warn()  { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] [AVISO] $*${NC}"; }
log_error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] [ERRO] $*${NC}" >&2; }

# --- Validação de arquivos ---------------------------------------------------

# Existe e não está vazio
is_valid_output() {
    [ -s "$1" ]
}

# Existe, não vazio, e começa com '>' (fasta válido)
is_valid_fasta() {
    local f="$1"
    [ -s "$f" ] || return 1
    [ "$(head -c1 "$f")" = ">" ] || return 1
    return 0
}

# --- Checagem genérica de amostra já processada ------------------------------
#
# skip_if_done <descrição> <arquivo_ou_pasta_de_output> <comando...>
#
# Se o output já existe e é válido (arquivo não-vazio, ou pasta não-vazia),
# pula a execução e loga [SKIP]. Caso contrário, roda o comando e loga [RUN].
# Uso:
#   skip_if_done "Prodigal para $base" "$faa" \
#       prodigal -i "$genome" -a "$faa" -d "$ffn" -o "$gff" -f gff -p meta -q
skip_if_done() {
    local descricao="$1"
    local output="$2"
    shift 2

    local ja_existe=false
    if [ -d "$output" ]; then
        [ -n "$(ls -A "$output" 2>/dev/null)" ] && ja_existe=true
    else
        is_valid_output "$output" && ja_existe=true
    fi

    if [ "$ja_existe" = true ]; then
        log "[SKIP] ${descricao} (já existe: ${output})"
        return 0
    fi

    log "[RUN] ${descricao}"
    "$@"
}

# --- Loop em lote sobre uma lista de amostras, com resumo de falhas ---------
#
# run_batch <script> <amostra1> <amostra2> ...
# Usa um array associativo pra reportar quais amostras falharam no final.
# Uso:
#   run_batch scripts/binning/run_metabat2.sh \
#       Mangrove/VAN1/ Mangrove/VAN2/ atlantic_florest/MAF1/
run_batch() {
    local script="$1"
    shift
    local amostras=("$@")
    local FAILED=()

    for amostra in "${amostras[@]}"; do
        log "Processando ${amostra}"
        if ! "$script" "$amostra"; then
            FAILED+=("$amostra")
        fi
    done

    echo
    log "===== RESUMO ====="
    if [ ${#FAILED[@]} -gt 0 ]; then
        log_warn "Falharam:"
        printf '%s\n' "${FAILED[@]}"
        return 1
    else
        log "Todas concluídas com sucesso."
        return 0
    fi
}

# --- Registro de versões das ferramentas (auditoria/reprodutibilidade) -----
#
# log_tool_version <nome_da_ferramenta> <comando_para_obter_versao...>
# Acumula em $VERSION_LOG (defina essa variável no script chamador antes
# de usar, ex: VERSION_LOG="logs/tool_versions.txt").
# Uso:
#   VERSION_LOG="logs/tool_versions.txt"
#   : > "$VERSION_LOG"
#   log_tool_version "Prodigal" prodigal -v
#   log_tool_version "RGI"      rgi main --version
log_tool_version() {
    local nome="$1"
    shift
    local versao
    versao="$("$@" 2>&1 | head -n1)"
    echo "${nome}: ${versao}" >> "${VERSION_LOG:-/dev/stdout}"
}
