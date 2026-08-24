#!/usr/bin/env bash
# =============================================================================
# run_magscot.sh
#
# Pipeline completo de refinamento de bins com MAGScoT:
#   Prodigal -> HMMsearch (TIGRFAM + Pfam) -> contigs_to_bin.tsv -> MAGScoT.R
#   -> extract_mags.py
#
# Cada etapa é pulada se o output já existir (skip granular, igual ao padrão
# usado em annotation/run_prodigal_rgi.sh). Isso substitui os dois scripts
# antigos (run_magscot.sh + magscot_final.sh) -- o segundo era basicamente o
# primeiro sem as etapas de Prodigal/HMMsearch, assumindo que o .hmm já
# existia. Com skip granular, um único script cobre os dois casos.
#
# Ferramenta: MAGScoT (https://github.com/ikmb/MAGScoT)
# Dependências: Prodigal, HMMER (hmmsearch), R (MAGScoT.R)
# conda: MAGScoT_env
#
# Uso:
#   ./run_magscot.sh <sample_dir>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/checks.sh"

if [ $# -ne 1 ]; then
    log_error "Uso: $0 <sample_dir>"
    exit 1
fi

# Ajuste este caminho para onde o repositório MAGScoT (clonado do GitHub) está
MAGSCOT_DIR="${MAGSCOT_DIR:-MAGScoT}"

### Caminhos
amostra="${1%/}"   # remove "/" final se existir
sample_name=$(basename "$amostra")

fasta="${amostra}/metaspades_out/scaffolds.fasta"
outdir="${amostra}/magscot_out"

mkdir -p "$outdir"

log "Sample: $sample_name"
log "Assembly: $fasta"

faa="${outdir}/${sample_name}.prodigal.faa"
ffn="${outdir}/${sample_name}.prodigal.ffn"
tigr_hits="${outdir}/${sample_name}.hmm.tigr.hit.out"
pfam_hits="${outdir}/${sample_name}.hmm.pfam.hit.out"
hmm_combined="${outdir}/${sample_name}.hmm"
contigs_to_bin="${outdir}/${sample_name}.contigs_to_bin.tsv"
refined_out="${outdir}/MAGScoT.refined.contig_to_bin.out"

# --- 1. Prodigal ---
if is_valid_output "$faa"; then
    log "[SKIP] Prodigal já feito para $sample_name."
else
    log "[RUN] Prodigal para $sample_name..."
    prodigal -i "$fasta" -p meta -a "$faa" -d "$ffn" -o "$outdir/prodigal.gff"
fi

# --- 2. HMMsearch (TIGRFAM + Pfam) ---
if is_valid_output "$tigr_hits" && is_valid_output "$pfam_hits"; then
    log "[SKIP] HMMsearch já feito para $sample_name."
else
    log "[RUN] HMMsearch (TIGRFAM) para $sample_name..."
    hmmsearch \
        -o "$outdir/${sample_name}.hmm.tigr.out" \
        --tblout "$tigr_hits" \
        --noali --notextw --cut_nc --cpu 16 \
        "${MAGSCOT_DIR}/hmm/gtdbtk_rel207_tigrfam.hmm" \
        "$faa"

    log "[RUN] HMMsearch (Pfam) para $sample_name..."
    hmmsearch \
        -o "$outdir/${sample_name}.hmm.pfam.out" \
        --tblout "$pfam_hits" \
        --noali --notextw --cut_nc --cpu 16 \
        "${MAGSCOT_DIR}/hmm/gtdbtk_rel207_Pfam-A.hmm" \
        "$faa"
fi

# --- 3. Combinar hits num único .hmm ---
if is_valid_output "$hmm_combined"; then
    log "[SKIP] Arquivo .hmm combinado já existe para $sample_name."
else
    awk '!/^#/{print $1"\t"$3"\t"$5}' "$tigr_hits" > "${outdir}/${sample_name}.tigr"
    awk '!/^#/{print $1"\t"$3"\t"$5}' "$pfam_hits" > "${outdir}/${sample_name}.pfam"
    cat "${outdir}/${sample_name}.pfam" "${outdir}/${sample_name}.tigr" > "$hmm_combined"
fi

# --- 4. contigs_to_bin.tsv (a partir dos 3 binners) ---
if is_valid_output "$contigs_to_bin"; then
    log "[SKIP] contigs_to_bin.tsv já existe para $sample_name."
else
    log "[RUN] Gerando contigs_to_bin.tsv..."
    python3 "${SCRIPT_DIR}/obtain_contigs_to_bin.py" "$amostra"
fi

# --- 5. MAGScoT.R (refinamento) ---
if is_valid_output "$refined_out"; then
    log "[SKIP] MAGScoT já refinado para $sample_name."
else
    log "[RUN] Rodando MAGScoT.R..."
    Rscript "${MAGSCOT_DIR}/MAGScoT.R" -i "$contigs_to_bin" --hmm "$hmm_combined"
    mv MAGScoT.* "$outdir/"
fi

# --- 6. Extrair fasta de cada bin refinado ---
log "[RUN] Extraindo MAGs refinados..."
python3 "${SCRIPT_DIR}/extract_mags.py" "$amostra"

log "MAGScoT finalizado para $sample_name!"
