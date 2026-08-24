# Ferramentas de Bioinformática
Author: Rodrigo Lusa (lusarodrigo4@gmail.com)

> Referência de todas as ferramentas usadas nos pipelines de bactérias e
> metagenoma, agrupadas por etapa. Cada ferramenta tem: link do GitHub,
> resumo, script(s) correspondente(s) em `scripts/`, e a estrutura de pastas
> que ela gera. Scripts pulam (skip) amostras já processadas — ver
> `scripts/lib/checks.sh`.

**Índice rápido:** [Download](#download) · [QC](#qc) · [Montagem](#assembly) · [Mapeamento](#mapping) · [Binning](#binning) · [Refinamento de bins](#bin-refinement) · [Anotação](#annotation) · [AMR](#amr) · [Visualização](#viz)

---

<a name="download"></a>
<details>
<summary><h2>📥 Download</h2></summary>

### NCBI `datasets`
[github.com/ncbi/datasets](https://github.com/ncbi/datasets)
Ferramenta oficial do NCBI para baixar genomas/assemblies em lote a partir de accessions.

- **Script:** `scripts/download/download_genomes.py`
- **Versão testada:** 18.16.0
- **Uso:** `python3 download_genomes.py genome_ids.txt -o fasta_files`
- **Skip:** pula IDs cujo `.fna` já existe e não está vazio.

**Estrutura gerada:**
```text
fasta_files/
├── GCA_000793345.1.fna
├── GCA_000793346.2.fna
└── ...
```

### `sra-tools` (prefetch + fasterq-dump)
[github.com/ncbi/sra-tools](https://github.com/ncbi/sra-tools)
Baixa `.sra` de uma run pública e converte pra FASTQ.

- **Script:** `scripts/download/baixar_reads_sra.sh`
- **Versão testada:** 3.2.1
- **Uso:** `./baixar_reads_sra.sh runs.txt outdir/`
- **Skip:** pula runs cujo `.fastq.gz` já existe no outdir.

**Estrutura gerada:**
```text
outdir/
├── SRR18469381_1.fastq.gz
├── SRR18469381_2.fastq.gz
└── ...
```

</details>

<a name="qc"></a>
<details>
<summary><h2>🧹 QC / Trimming</h2></summary>

### fastp
[github.com/OpenGene/fastp](https://github.com/OpenGene/fastp)
Trimming e controle de qualidade de reads Illumina. Rápido, faz adapter
trimming automático e gera relatório HTML/JSON por amostra.

- **Script:** `scripts/qc/fastp_parallel.py` (roda `fastp` em paralelo pra todas as amostras de uma pasta + agrega tudo num `overall.html`)
- **Versão testada:** v1.1.0
- **Parâmetros usados** (seguindo Xu et al. 2025, [doi.org/10.1016/j.synbio.2025.07.006](https://doi.org/10.1016/j.synbio.2025.07.006)):
  ```bash
  python fastp_parallel.py -i raw_reads/ -o trimmed_reads/ -r fastp_reports/ \
      -a "--detect_adapter_for_pe --cut_front --cut_tail -W 4 -M 20 -l 50 -n 3 -u 40 -w 4"
  ```
- **Skip:** pula pares de reads cujo `.clean.fastq.gz` já existe em `out_dir`.

**Estrutura gerada:**
```text
trimmed_reads/
├── amostra_R1.clean.fastq.gz
└── amostra_R2.clean.fastq.gz
fastp_reports/
├── amostra_pe.html
├── amostra_pe.json
└── overall.html          # relatório agregado de todas as amostras
```

### bbtools `repair.sh`
[sourceforge.net/projects/bbmap](https://sourceforge.net/projects/bbmap) (BBTools)
Usado quando o metaSPAdes reclama de reads pareadas fora de sincronia — realinha
R1/R2 e separa singletons.
```bash
# conda activate bbtools
repair.sh in=R1.clean.fastq in2=R2.clean.fastq \
    out=R1_paired.fastq out2=R2_paired.fastq outs=singletons.fastq repair=t
```
*(sem wrapper próprio — comando único, roda direto)*

</details>

<a name="assembly"></a>
<details>
<summary><h2>🧬 Montagem</h2></summary>

### metaSPAdes
[github.com/ablab/spades](https://github.com/ablab/spades)
Montador escolhido após comparação com MEGAHIT (ver `teste_montadores.md` do
mestrado — metaSPAdes deu contigs com maior contiguidade). Modo `metaSPAdes`
do SPAdes.

- **Script:** `scripts/assembly/run_metaspades.sh`
- **Versão testada:** v3.13.1 [metaSPAdes mode]
- **Uso:** `./run_metaspades.sh <sample_dir>/`
- **Skip:** pula a amostra se `scaffolds.fasta` já existir.
- **Entrada esperada:** `<sample_dir>/reads/*1_paired*`, `*2_paired*`, `*singleton*`

**Estrutura gerada:**
```text
<sample_dir>/
└── metaspades_out/
    ├── scaffolds.fasta      # usado nas etapas seguintes
    ├── contigs.fasta
    └── ...
```

</details>

<a name="mapping"></a>
<details>
<summary><h2>🗺️ Mapeamento</h2></summary>

### Bowtie2 + Samtools
[github.com/BenLangmead/bowtie2](https://github.com/BenLangmead/bowtie2) ·
[github.com/samtools/samtools](https://github.com/samtools/samtools)
Mapeia as reads de volta contra o metagenoma montado — o BAM ordenado
resultante é a entrada de todos os binners.

- **Script:** `scripts/mapping/run_mapping.sh`
- **Versões testadas:** Bowtie2 v2.3.5.1, Samtools v1.17
- **Uso:** `./run_mapping.sh <sample_dir>/`
- **Skip:** pula a amostra se `mapping/alignment.sorted.bam(.bai)` já existir.
- **Nota:** consolida os antigos `make_bam_files.sh` e `pre_comebin.sh` (que
  faziam a mesma coisa) num script só, corrigindo um bug da versão antiga
  (variável `$SINGLE` indefinida em vez de `$singleton`).

**Estrutura gerada:**
```text
<sample_dir>/
└── mapping/
    ├── scaffold_index.*          # index do bowtie2
    ├── alignment.sorted.bam      # usado por MetaBAT2, MetaDecoder, COMEBin
    └── alignment.sorted.bam.bai
```

</details>

<a name="binning"></a>
<details>
<summary><h2>🗂️ Binning</h2></summary>

Os 3 binners rodam **em paralelo, independentemente**, sobre a mesma montagem
+ mapeamento — o refinamento (MAGScoT) depois decide qual bin de qual
ferramenta manter.

### MetaBAT2
[bitbucket.org/berkeleylab/metabat](https://bitbucket.org/berkeleylab/metabat/src/master/)
Binning por cobertura + composição de tetranucleotídeos. Instalado via Docker
no seu setup.

- **Script:** `scripts/binning/run_metabat2.sh`
- **Versão testada:** 2:2.17.89-gc869c52-dirty
- **Uso:** `./run_metabat2.sh <sample_dir>/`
- **Skip:** pula se a pasta de bins já existir.

**Estrutura gerada:**
```text
<sample_dir>/
├── metaspades_out/scaffolds.fasta.gz
└── scaffolds.fasta.gz.metabat-bins<N>/
    ├── bin.1.fa
    ├── bin.2.fa
    └── ...
```

### MetaDecoder
[github.com/liu-congcong/MetaDecoder](https://github.com/liu-congcong/MetaDecoder)
Binning usando modelo de linguagem (embedding) + cobertura.

- **Script:** `scripts/binning/run_metadecoder.sh`
- **Versão testada:** 1.2.2
- **Uso:** `./run_metadecoder.sh <sample_dir>/`
- **Skip:** pula se já existir `METADECODER.*.fasta`.

**Estrutura gerada:**
```text
<sample_dir>/
└── metadecoder_out/
    ├── METADECODER.COVERAGE
    ├── METADECODER.SEED
    ├── METADECODER.1.fasta      # bins finais
    ├── METADECODER.2.fasta
    └── ...
```

### COMEBin
[github.com/ziyewang/COMEBin](https://github.com/ziyewang/COMEBin/tree/master)
Binning por contrastive learning multi-view.

- **Script:** `scripts/binning/run_comebin.sh` **(wrapper novo)**
- **Uso:** `./run_comebin.sh <sample_dir>/`
- **Skip:** pula se já existirem bins em `comebin_out/comebin_res/comebin_res_bins/`.
- **Nota:** padronizei o nome da pasta de saída pra `comebin_out` (a
  documentação antiga usava `comebin_output`, mas o script de agregação
  espera `comebin_out`).

**Estrutura gerada:**
```text
<sample_dir>/
└── comebin_out/
    └── comebin_res/
        └── comebin_res_bins/
            ├── bin.1.fa
            └── ...
```

</details>

<a name="bin-refinement"></a>
<details>
<summary><h2>🧩 Refinamento de bins</h2></summary>

### MAGScoT
[github.com/ikmb/MAGScoT](https://github.com/ikmb/MAGScoT)
Combina os bins dos 3 binners (score por marcadores single-copy TIGRFAM/Pfam)
e escolhe o melhor conjunto não-redundante de bins refinados.

- **Script principal:** `scripts/bin_refinement/run_magscot.sh` — pipeline completo:
  `Prodigal → HMMsearch (TIGRFAM + Pfam) → contigs_to_bin.tsv → MAGScoT.R → extract_mags.py`
- **Scripts auxiliares:**
  - `obtain_contigs_to_bin.py` — junta os bins de ComeBin/MetaDecoder/MetaBAT2
    num único TSV `BIN<TAB>CONTIG<TAB>BINNER`
  - `extract_mags.py` — extrai um `.fasta` por bin refinado
  - `make_unbinned.py` — extrai os contigs que **não** caíram em nenhum bin
    (viram um pseudo-bin, também entram na entrada do ARGOS)
- **Uso:** `./run_magscot.sh <sample_dir>/` (precisa de `MAGSCOT_DIR` apontando
  pro clone do repositório MAGScoT — default: pasta `MAGScoT/` no cwd)
- **Skip:** granular por etapa (Prodigal, HMMsearch, tsv, refinamento — cada
  um só roda se o output daquela etapa específica não existir). Isso
  substitui os dois scripts antigos (`run_magscot.sh` + `magscot_final.sh`,
  que eram quase o mesmo script duplicado).

**Estrutura gerada:**
```text
<sample_dir>/
├── magscot_out/
│   ├── <amostra>.prodigal.faa/.ffn
│   ├── <amostra>.hmm.tigr.hit.out / .hmm.pfam.hit.out
│   ├── <amostra>.hmm                        # combinado
│   ├── <amostra>.contigs_to_bin.tsv
│   ├── MAGScoT.refined.out
│   ├── MAGScoT.refined.contig_to_bin.out    # mapeamento final contig -> bin
│   └── MAGScoT.scores.out
└── refined_mags/
    ├── <amostra>_bin_1.fasta
    ├── <amostra>_bin_2.fasta
    └── ...
```
E, rodando `make_unbinned.py` sobre todas as amostras:
```text
unbinned_contigs/
├── <amostra1>_unbinned.fasta
├── <amostra2>_unbinned.fasta
└── ...
```

### CheckM2
[github.com/chklovski/CheckM2](https://github.com/chklovski/CheckM2)
QC de completude/contaminação de genomas e MAGs.

- **Sem wrapper** — comando único, rodado sobre todos os MAGs de uma vez:
  ```bash
  conda activate checkm2
  checkm2 predict --threads 30 --input MAGs/ --output-directory MAGs_checkm_results
  ```
- **Versão testada:** 1.1.0
- **Filtro usado no projeto:** Completeness ≥ 98%, Contamination < 5%, N50 ≥ 10.000

**Estrutura gerada:**
```text
MAGs_checkm_results/
├── quality_report.tsv     # Completeness, Contamination, N50 por MAG
└── diamond_output/
```

</details>

<a name="annotation"></a>
<details>
<summary><h2>🏷️ Anotação</h2></summary>

### Prokka
[github.com/tseemann/prokka](https://github.com/tseemann/prokka)
Anotação rápida de genomas bacterianos completos (isolados) — gene calling +
anotação funcional numa etapa só.

- **Script:** `scripts/annotation/run_prokka.sh`
- **Versão testada:** v1.14.6
- **Uso:** `./run_prokka.sh [genomes_dir] [annotations_dir]`
- **Skip:** pula genoma já anotado (detecta pelo `.faa` de saída); remove e
  re-roda se encontrar uma pasta de output parcial (rodada anterior
  interrompida).
- **Correção:** a versão anterior deste script tinha um typo nas mensagens de
  log (`"nvalid FASTA"`, `"artial output"` — faltava a primeira letra); corrigido.

**Estrutura gerada:**
```text
prokka_annotations/
└── <genoma>/
    ├── <genoma>.faa      # usado no RGI
    ├── <genoma>.ffn
    ├── <genoma>.gff
    ├── <genoma>.gbk
    └── ...
```

### Prodigal
[github.com/hyattpd/Prodigal](https://github.com/hyattpd/Prodigal)
Gene calling standalone (mais rápido que Prokka, sem anotação funcional) —
usado nos MAGs, onde só precisamos das ORFs pro RGI/MAGScoT.

- **Script:** `scripts/annotation/run_prodigal_rgi.sh` (Prodigal + RGI juntos, ver [AMR](#amr))
- **Também usado dentro de:** `scripts/bin_refinement/run_magscot.sh`

### geNomad
[github.com/apcamargo/genomad](https://github.com/apcamargo/genomad)
Classifica cada contig como cromossomo / plasmídeo / vírus — usado pra
cruzar mobilidade genética com risco de AMR (quantos genes Rank I estão em
contigs de plasmídeo, por exemplo).

- **Script:** `scripts/annotation/run_genomad.sh`
- **Uso:** `./run_genomad.sh <input_dir> <output_dir> <db_path>`
- **Skip:** pula genoma cuja pasta de output já não está vazia.

**Estrutura gerada (por genoma):**
```text
output_dir/<genoma>/
├── <genoma>_summary/
│   ├── <genoma>_virus_summary.tsv
│   ├── <genoma>_plasmid_summary.tsv
│   └── ...
└── <genoma>_find_proviruses/
```

</details>

<a name="amr"></a>
<details>
<summary><h2>💊 AMR (Antimicrobial Resistance)</h2></summary>

### RGI + CARD
[github.com/arpcard/rgi](https://github.com/arpcard/rgi)
Anota genes de resistência a antimicrobianos comparando proteínas preditas
contra o banco CARD/WildCARD.

- **Script (isolados, a partir de `.faa` do Prokka):** `scripts/amr/run_rgi.sh`
- **Script (MAGs, Prodigal + RGI num pipeline só):** `scripts/annotation/run_prodigal_rgi.sh`
- **Versões testadas:** RGI v6.0.5, CARD 4.0.1, WildCARD 3.2.7
- **Skip:** ambos pulam amostra já processada (detecta pelo `_rgi.txt` de saída).
- **Correção:** `run_rgi.sh` documentava modo `--local` no comentário mas o
  comando não tinha a flag — adicionada, pra bater com o que está
  documentado.

**Estrutura gerada (`run_rgi.sh`, por isolado):**
```text
<isolado>/
├── <isolado>.faa
└── <isolado>_rgi.txt      # tabela de genes de resistência
```

**Estrutura gerada (`run_prodigal_rgi.sh`, por MAG):**
```text
prodigal_out/<mag>.faa/.ffn/.gff/.gbk
prodigal_clean/<mag>.faa        # sem '*' de stop codon (exigido pelo RGI)
rgi_out/<mag>/<mag>_rgi.txt
resistome/<mag>_rgi.txt         # cópia final -- entrada do ARGOS
logs/tool_versions.txt
```

### RGI-BWT (KMA)
[docs (rgi_bwt)](https://github.com/arpcard/rgi/blob/master/docs/rgi_bwt.rst)
Alternativa ao Prodigal+RGI: mapeia as **reads** direto contra CARD/WildCARD
via KMA, sem precisar montar/anotar genes antes.

- **Script:** `scripts/amr/run_rgi_bwt.sh`
- **Uso:** `./run_rgi_bwt.sh read_1.fastq read_2.fastq outdir/ [nome_amostra]`
- **Skip:** pula amostra já mapeada.

**Estrutura gerada:**
```text
outdir/
└── <amostra>_kma_mapping_out.gene_mapping_data.txt   # usado nas análises seguintes
```

### group_resistome.py
Não é uma ferramenta externa — é o script que agrega todas as tabelas
`_rgi.txt` de uma pasta num único CSV (`Assembly` extraído do nome do
arquivo), pronto pra virar entrada do ARGOS.

- **Script:** `scripts/amr/group_resistome.py`
- **Uso:** `python group_resistome.py rgi_txt_files/ -o resistoma_total.csv`
- **Correção:** antes existia duplicado (uma cópia por projeto, cada uma com
  o nome do CSV de saída hardcoded). Agora `-o` é parâmetro — um script só
  serve qualquer projeto.

</details>

<a name="viz"></a>
<details>
<summary><h2>📊 Visualização</h2></summary>

### Blobtools
[github.com/DRL/blobtools](https://github.com/DRL/blobtools)
Gera "blobplots" (GC% × cobertura, colorido por taxonomia ou por bin) — bom
pra checar contaminação/heterogeneidade numa montagem de metagenoma.

- **Script:** `scripts/viz/run_blobtools.sh` — consolida BLASTn + DIAMOND +
  `blobtools create/view/plot` num pipeline só, com skip por etapa.
- **Script auxiliar:** `scripts/viz/bin2catcolour.py` — gera o TSV de cor por
  bin (`--catcolour`), a partir dos `.fna` dos bins na pasta atual.
- **Versões testadas:** Blobtools 1.1.1, BLASTn 2.17.0+, DIAMOND 2.1.24.178
- **Uso:**
  ```bash
  python bin2catcolour.py                     # gera blobplot_bin_colour.tsv
  ./run_blobtools.sh scaffolds.fasta alignment.sorted.bam meu_blobplot blobplot_bin_colour.tsv
  ```

**Estrutura gerada:**
```text
meu_blobplot.blast.out
meu_blobplot.diamond.out
meu_blobplot.blobDB.json
meu_blobplot.<taxlevel>.p8.span.100.blobplot.bam0.png   # o gráfico
```

</details>

---

## Rodando em lote (todas as amostras)

Todo script de `scripts/*/run_*.sh` aceita uma amostra por chamada. Pra rodar
numa lista de amostras com resumo de falhas no final, use `run_batch` de
`lib/checks.sh`:
```bash
#!/usr/bin/env bash
source scripts/lib/checks.sh

run_batch scripts/binning/run_metabat2.sh \
    Mangrove/VAN1/ \
    Mangrove/VAN2/ \
    atlantic_florest/MAF1/
```
Como cada script já pula amostras/etapas já processadas, rodar esse loop de
novo depois de uma falha no meio do caminho é seguro — só as amostras que
faltaram (ou falharam) vão de fato rodar de novo.
