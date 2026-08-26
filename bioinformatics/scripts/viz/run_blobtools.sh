#!/usr/bin/env bash
# =============================================================================
# run_blobtools.sh
#
# Gera um blobplot (GC% x cobertura x taxonomia) pra checar contaminação
# em uma montagem de metagenoma. Consolida os passos manuais documentados
# no projeto (BLASTn + DIAMOND -> blobtools create/view/plot).
#
# Ferramentas: Blobtools 1.1.1, BLASTn 2.17.0+, DIAMOND 2.1.24.178
# https://github.com/DRL/blobtools
#
# Pré-requisitos (não automatizados aqui, rodar uma vez):
#   - banco nt do BLAST:      update_blastdb.pl nt --decompress
#   - banco DIAMOND UniProt:  diamond makedb --in reference_proteomes.fasta -d uniprot_db
#
# Uso:
#   ./run_blobtools.sh <assembly.fasta> <alignment.sorted.bam> <outprefix> [catcolour.tsv]
#
# catcolour.tsv (opcional) -- gerado por bin2catcolour.py -- colore os
# contigs por bin em vez de por taxonomia.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -lt 3 ]; then
    log_error "Uso: $0 <assembly.fasta> <alignment.sorted.bam> <outprefix> [catcolour.tsv]"
    exit 1
fi

ASSEMBLY="$1"
BAM="$2"
OUTPREFIX="$3"
CATCOLOUR="${4:-}"

NT_DB="${NT_DB:-databases/blastdb/nt}"
DIAMOND_DB="${DIAMOND_DB:-uniprot_ref_proteomes.diamond.dmnd}"

BLAST_OUT="${OUTPREFIX}.blast.out"
DIAMOND_OUT="${OUTPREFIX}.diamond.out"
BLOBDB="${OUTPREFIX}.blobDB.json"

# --- 1. BLASTn contra nt ---
if is_valid_output "$BLAST_OUT"; then
    log "[SKIP] BLASTn já feito ($BLAST_OUT existe)"
else
    log "[RUN] BLASTn contra nt..."
    blastn \
        -query "$ASSEMBLY" \
        -db "$NT_DB" \
        -outfmt "6 qseqid staxids bitscore std" \
        -max_target_seqs 1 \
        -max_hsps 1 \
        -evalue 1e-25 \
        -num_threads 8 \
        -out "$BLAST_OUT"
fi

# --- 2. DIAMOND blastx contra UniProt Reference Proteomes ---
if is_valid_output "$DIAMOND_OUT"; then
    log "[SKIP] DIAMOND já feito ($DIAMOND_OUT existe)"
else
    log "[RUN] DIAMOND blastx contra UniProt..."
    diamond blastx \
        --query "$ASSEMBLY" \
        --db "$DIAMOND_DB" \
        --outfmt 6 \
        --sensitive \
        --max-target-seqs 1 \
        --evalue 1e-25 \
        -o "$DIAMOND_OUT" \
        --threads 10
fi

# --- 3. blobtools create ---
if is_valid_output "$BLOBDB"; then
    log "[SKIP] blobtools create já feito ($BLOBDB existe)"
else
    log "[RUN] blobtools create..."
    blobtools create \
        -i "$ASSEMBLY" \
        -b "$BAM" \
        -t "$BLAST_OUT" \
        -t "$DIAMOND_OUT" \
        --taxrule bestsumorder \
        -o "$OUTPREFIX"
fi

# --- 4. blobtools view (tabela texto) ---
log "[RUN] blobtools view..."
blobtools view -i "$BLOBDB" -o "$OUTPREFIX"

# --- 5. blobtools plot ---
log "[RUN] blobtools plot..."
if [ -n "$CATCOLOUR" ]; then
    blobtools plot -i "$BLOBDB" --catcolour "$CATCOLOUR" -o "$OUTPREFIX"
else
    blobtools plot -i "$BLOBDB" -o "$OUTPREFIX"
fi

log "Blobplot finalizado: ${OUTPREFIX}*"
