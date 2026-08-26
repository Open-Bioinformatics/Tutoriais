#!/usr/bin/env bash
# =============================================================================
# run_comebin.sh
#
# Wrapper do COMEBin numa amostra já montada e mapeada. Pula a amostra se
# já existirem bins do COMEBin.
#
# Ferramenta: COMEBin (testado seguindo o binning.md do projeto)
# https://github.com/ziyewang/COMEBin
# conda: comebin (ou o ambiente que você usa para instalar o COMEBin)
#
# NOTA: padronizei o nome da pasta de saída para "comebin_out" (era
# "comebin_output" na documentação antiga) porque é o que
# obtain_contigs_to_bin.py espera em:
#   <amostra>/comebin_out/comebin_res/comebin_res_bins/
#
# Uso:
#   ./run_comebin.sh <sample_dir>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 1 ]; then
    log_error "Uso: $0 <sample_dir>"
    exit 1
fi

amostra="$1"
assembly="${amostra}metaspades_out/scaffolds.fasta"
mapping_dir="${amostra}mapping"
outdir="${amostra}comebin_out"
bins_dir="${outdir}/comebin_res/comebin_res_bins"

# --- skip se já existem bins do COMEBin ---
if compgen -G "${bins_dir}/"*".fa" > /dev/null || compgen -G "${bins_dir}/"*".fna" > /dev/null; then
    log "[SKIP] ${amostra} já binada pelo COMEBin"
    exit 0
fi

log "Processando a amostra ${amostra}"
log "Assembly: ${assembly}"
log "BAM dir: ${mapping_dir}"

run_comebin.sh \
    -a "$assembly" \
    -o "$outdir" \
    -p "$mapping_dir" \
    -t 32

log "COMEBin finalizado para ${amostra}"
