#!/usr/bin/env bash
# =============================================================================
# baixar_reads_sra.sh
#
# Baixa e converte reads públicas do SRA (prefetch + fasterq-dump), a partir
# de uma lista de run accessions (uma por linha). Pula runs já baixadas.
#
# Ferramentas: sra-tools (prefetch, fasterq-dump)
# https://github.com/ncbi/sra-tools
# conda: ncbi_datasets  |  testado com prefetch/fasterq-dump 3.2.1
#
# Uso:
#   ./baixar_reads_sra.sh runs.txt [outdir]
#
# Exemplo de runs.txt:
#   SRR18469381
#   ERR11831051
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -lt 1 ]; then
    echo "Uso: $0 runs.txt [outdir]"
    exit 1
fi

RUNS_FILE="$1"
OUTDIR="${2:-.}"
mkdir -p "$OUTDIR"

while read -r run; do
    [ -z "$run" ] && continue

    # já baixado e convertido? (checa se existe pelo menos um .fastq.gz do run)
    if compgen -G "${OUTDIR}/${run}"*".fastq.gz" > /dev/null; then
        log "[SKIP] ${run} já baixado em ${OUTDIR}"
        continue
    fi

    log "[RUN] Processando ${run}"
    prefetch "$run" -O "$OUTDIR"
    fasterq-dump "${OUTDIR}/${run}" --split-files --threads 8 -O "$OUTDIR"
    gzip "${OUTDIR}/${run}"*.fastq
    log "  -> ${run} finalizado"
done < "$RUNS_FILE"

log "Download de reads finalizado."
