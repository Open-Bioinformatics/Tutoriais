#!/usr/bin/env bash
# =============================================================================
# run_metabat2.sh
#
# Roda o MetaBAT2 (via Docker) numa amostra já montada e mapeada.
# Pula a amostra se já existir pasta de bins do MetaBAT2.
#
# Ferramenta: MetaBAT2 (instalado via Docker, testado com 2:2.17.89-gc869c52-dirty)
# https://bitbucket.org/berkeleylab/metabat/src/master/
#
# Uso:
#   ./run_metabat2.sh <sample_dir>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 1 ]; then
    log_error "Uso: $0 <sample_dir>"
    exit 1
fi

SAMPLE_DIR="${1}"

# --- skip se já existe pasta de bins do MetaBat2 ---
if compgen -G "${SAMPLE_DIR}scaffolds.fasta.gz.metabat-bins"*"/bin.*.fa" > /dev/null; then
    log "[SKIP] ${SAMPLE_DIR} já binada pelo MetaBAT2"
    exit 0
fi

cd "$SAMPLE_DIR"

log "Processing sample: ${SAMPLE_DIR}"

log "Gzipping fasta file..."
gzip -c metaspades_out/scaffolds.fasta > metaspades_out/scaffolds.fasta.gz

log "Running MetaBat2..."
docker run --rm \
    -v "$(pwd)":"$(pwd)" \
    -w "$(pwd)" \
    metabat:latest \
    runMetaBat.sh \
    metaspades_out/scaffolds.fasta.gz \
    mapping/alignment.sorted.bam

log "Finished processing ${SAMPLE_DIR}"
