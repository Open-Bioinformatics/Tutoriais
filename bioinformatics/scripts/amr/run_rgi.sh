#!/usr/bin/env bash
# =============================================================================
# run_rgi.sh
#
# Roda o RGI (contra o banco CARD) em todos os .faa de uma pasta -- usado
# na anotação de AMR de isolados já anotados pelo Prokka. Pula amostras já
# processadas.
#
# Ferramenta: RGI + CARD (testado com RGI v6.0.5, CARD 4.0.1, WildCARD 3.2.7)
# https://github.com/arpcard/rgi
# conda: rgi_env  |  modo local (--local), dependências via bioconda/conda-forge
#
# Uso:
#   ./run_rgi.sh [pasta_com_faa]
#   (default: diretório atual)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

faa_dir="${1:-.}"

shopt -s nullglob
files=("$faa_dir"/*.faa)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    log_error "Nenhum arquivo .faa encontrado em $faa_dir"
    exit 1
fi

for file in "${files[@]}"; do
    base=$(basename "$file" .faa)
    rgi_txt="${base}/${base}_rgi.txt"

    if is_valid_output "$rgi_txt"; then
        log "[SKIP] RGI já feito para $base."
        continue
    fi

    log "[RUN] Processando: $file"
    mkdir -p "$base"
    cp "$file" "$base/"

    rgi main \
        -i "$base/$(basename "$file")" \
        -o "$base/${base}_rgi" \
        -t protein --local

    log "Finalizado: $base"
done

log "Todos os arquivos foram processados."
