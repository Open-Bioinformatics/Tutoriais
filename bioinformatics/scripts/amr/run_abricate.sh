#!/usr/bin/env bash
# =============================================================================
# run_abricate.sh
#
# Roda ABRicate em cada genoma contra os bancos NÃO relacionados a resistência
# (resistência já é coberta pelo RGI/CARD, mais completo/atualizado pra AMR):
#   - vfdb          (fatores de virulência)
#   - plasmidfinder  (replicons de plasmídeo)
#   - ecoh           (antígenos O/H de E. coli)
#   - ecoli_vf       (fatores de virulência específicos de E. coli)
#
# Bancos EXCLUÍDOS de propósito (redundantes com RGI/CARD): card, resfinder,
# argannot, megares, ncbi.
#
# Paralelizado ENTRE genomas via GNU parallel (ABRicate é rápido/single-core
# por chamada -- o ganho em escala vem de rodar muitos genomas ao mesmo tempo).
# Pula combinação genoma+banco já processada.
#
# Ferramenta: ABRicate (testado com v1.0.1)
# https://github.com/tseemann/abricate
#
# Uso:
#   ./run_abricate.sh [genomes_dir] [JOBS]
#   (defaults: genomes_dir=genomes, JOBS=64)
# =============================================================================

set -uo pipefail   # sem -e: uma falha num genoma não pode matar o parallel inteiro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

GENOMES_DIR="${1:-genomes}"
JOBS="${2:-64}"

DATABASES=(vfdb plasmidfinder ecoh ecoli_vf)
OUTDIR="abricate_out"
LOG_DIR="logs"

mkdir -p "$OUTDIR" "$LOG_DIR"

if ! command -v parallel &> /dev/null; then
    log_error "GNU parallel não encontrado. Instale com: conda install -c conda-forge parallel"
    exit 1
fi

# --- Função que processa 1 genoma contra todos os bancos não-resistência ---
process_genome() {
    local genome="$1"
    local outdir="$2"
    shift 2
    local databases=("$@")
    local base
    base=$(basename "$genome")
    base="${base%.*}"

    if ! is_valid_fasta "$genome"; then
        log_error "$genome não é um fasta válido ou está vazio. Pulando $base."
        return 1
    fi

    mkdir -p "${outdir}/${base}"

    for db in "${databases[@]}"; do
        local out_tab="${outdir}/${base}/${base}_${db}.tab"

        if is_valid_output "$out_tab"; then
            log "[SKIP] ${base} / ${db} já processado."
            continue
        fi

        log "[RUN] ${base} / ${db}..."
        abricate --db "$db" --quiet "$genome" > "$out_tab"
    done
}
export -f process_genome
export -f log log_error is_valid_output is_valid_fasta

shopt -s nullglob
genomes=("$GENOMES_DIR"/*.fna "$GENOMES_DIR"/*.fasta)
shopt -u nullglob

if [ ${#genomes[@]} -eq 0 ]; then
    log_error "Nenhum genoma (.fna/.fasta) encontrado em $GENOMES_DIR"
    exit 1
fi

log "Total de genomas: ${#genomes[@]} | Bancos: ${DATABASES[*]} | JOBS simultâneos: $JOBS"

printf '%s\n' "${genomes[@]}" | \
    parallel -j "$JOBS" --joblog "${LOG_DIR}/abricate.joblog" \
        process_genome {} "$OUTDIR" "${DATABASES[@]}"

# --- Resumo consolidado (--summary) por banco, útil pra checagem rápida ---
for db in "${DATABASES[@]}"; do
    summary="${OUTDIR}/summary_${db}.tab"
    log "Gerando resumo consolidado: $summary"
    abricate --summary "${OUTDIR}"/*/*"_${db}.tab" > "$summary" 2>/dev/null || true
done

n_total=$(($(wc -l < "${LOG_DIR}/abricate.joblog") - 1))
n_falha=$(awk 'NR>1 && $7!=0' "${LOG_DIR}/abricate.joblog" | wc -l)
log "===== RESUMO ====="
log "Total: $n_total | OK: $((n_total - n_falha)) | Falhas: $n_falha"
log "Resumos consolidados em ${OUTDIR}/summary_<banco>.tab"
