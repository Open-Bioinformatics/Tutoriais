# Tutorial Python + Bash
Author: Rodrigo Lusa (lusarodrigo4@gmail.com)

> Compilado de referências rápidas — bash básico, pandas, numpy/matplotlib/seaborn,
> estruturação de funções, comprehensions e typer. Objetivo: consultar aqui antes
> de perguntar pra IA.

**Índice rápido:** [🐧 Linux](#linux) · [🐍 Python](#python) · [🔗 Links Úteis](#links-uteis)

---

<a name="linux"></a>
<details>
<summary><h1>🐧 1. LINUX / BASH</h1></summary>

## 1.1 Script básico (anatomia)
```bash
#!/bin/bash
# Shebang: diz ao sistema qual interpretador usar pra rodar o script

# Variáveis (sem espaço ao redor do =)
PASTA="resultados"
EXT=".fasta"

# Usando a variável -> $VAR ou ${VAR}
echo "Procurando arquivos $EXT em $PASTA"

# Argumentos de linha de comando
# $0 = nome do script, $1 = primeiro argumento, $2 = segundo, etc.
# $# = número de argumentos, $@ = todos os argumentos
echo "Script: $0"
echo "Primeiro argumento: $1"
echo "Total de argumentos: $#"

# Rodar: bash script.sh amostra1
```

Dar permissão de execução e rodar direto:
```bash
chmod +x script.sh
./script.sh amostra1
```

## 1.2 if / else
```bash
#!/bin/bash
ARQUIVO=$1

# Sintaxe: espaço depois de [ e antes de ]  é obrigatório
if [ -f "$ARQUIVO" ]; then
    echo "É um arquivo"
elif [ -d "$ARQUIVO" ]; then
    echo "É um diretório"
else
    echo "Não existe: $ARQUIVO"
fi
```

Testes mais usados dentro de `[ ]`:
```bash
-f arquivo      # existe e é arquivo comum
-d pasta        # existe e é diretório
-e caminho      # existe (arquivo ou pasta)
-s arquivo      # existe e não está vazio (size > 0)
-r / -w / -x    # tem permissão de leitura / escrita / execução

# Comparação de strings
[ "$a" == "$b" ]     # igual
[ "$a" != "$b" ]     # diferente
[ -z "$a" ]           # string vazia
[ -n "$a" ]           # string não vazia

# Comparação numérica (NÃO usa == para números)
[ "$a" -eq "$b" ]    # igual
[ "$a" -ne "$b" ]    # diferente
[ "$a" -gt "$b" ]    # maior que
[ "$a" -lt "$b" ]    # menor que
[ "$a" -ge "$b" ]    # maior ou igual
[ "$a" -le "$b" ]    # menor ou igual

# Combinando condições
if [ -f "$ARQUIVO" ] && [ -s "$ARQUIVO" ]; then   # E
if [ -f "$ARQUIVO" ] || [ -d "$ARQUIVO" ]; then   # OU
```

## 1.3 Loops (for / while) — pra checagem em massa
```bash
# For sobre arquivos (glob)
for f in *.fastq.gz; do
    echo "Processando $f"
done

# For sobre uma lista de amostras
AMOSTRAS="MAF1 MAF2 MAF3"
for amostra in $AMOSTRAS; do
    echo "Amostra: $amostra"
done

# While lendo linha por linha de um arquivo (ex: lista de samples)
while read -r linha; do
    echo "Sample: $linha"
done < lista_samples.txt
```

## 1.4 Script de checagem rápida (exemplo real de uso)
Padrão pra checar se todos os arquivos esperados de um pipeline existem:
```bash
#!/bin/bash
# uso: bash checar_outputs.sh lista_samples.txt pasta_resultados/

LISTA=$1
PASTA=$2

while read -r sample; do
    ARQ="${PASTA}/${sample}_rgi.txt"
    if [ -s "$ARQ" ]; then
        echo "OK    - $sample"
    else
        echo "FALTA - $sample ($ARQ)"
    fi
done < "$LISTA"
```

## 1.5 Extras úteis pra análise rápida de arquivos
```bash
# Contar quantas sequências tem num fasta
grep -c "^>" arquivo.fasta

# Contar linhas de um fastq (÷4 = número de reads)
zcat amostra.fastq.gz | wc -l

# Ver só o cabeçalho de um csv/tsv grande
head -1 tabela.csv

# Checar tamanho de vários arquivos de uma vez
du -sh *.fastq.gz

# Loop + condicional pra mover arquivos vazios pra revisão
mkdir -p revisar
for f in *.txt; do
    if [ ! -s "$f" ]; then
        mv "$f" revisar/
    fi
done

# set -e: para o script se algum comando falhar (bom pra scripts de pipeline)
set -e
set -u   # erro se usar variável não definida
```

## 1.6 Outros tutoriais de Linux do repositório
Estes ficam como arquivos próprios em `linux/` (não duplicados aqui, são temas
específicos demais pra virarem seção deste notebook):
- `linux/find.md` — cheat sheet completo de `find` (busca por nome/caminho/tempo,
  `-exec`, renomear em massa, extrair campos com `cut`/`rev`/`awk`)
- `linux/seqkit.md` — manipulação de FASTA/FASTQ com `seqkit` (stats, seq, subseq, grep)
- `linux/docker_setup.md` — Docker + Jupyter em servidor remoto (conceitos de container,
  Dockerfile, imagem, volume, port mapping)
- `linux/Trillium.md` — acesso e uso do cluster Trillium (SSH, `scp`, `module`, SLURM)

</details>

---

<a name="python"></a>
<details open>
<summary><h1>🐍 2. PYTHON</h1></summary>

<details>
<summary><h2>2.1 Pandas</h2></summary>

### 2.1.1 Do caderno (transcrição completa)

**Import e inspeção**
```python
df = pd.read_csv('file')              # csv
df = pd.read_csv('file', sep='\t')    # tsv

df.columns                            # nomes das colunas
df.dtypes                             # tipo de cada coluna
df.describe()                         # estatísticas gerais (numéricas)
```

**Seleção de colunas e filtro**
```python
df['coluna']
df[['coluna1', 'coluna2']]            # lista de colunas

# Filtrar
df[df['Amostra'] == 'MAF1']
df[df['Amostra'].isin(['MAF1', 'MAF2'])]

# And / Or -> sempre com parênteses em cada condição (x | y)
df[(df['LFQ'] > 10) & (df['p'] < 0.05)]

# Texto
df[df['gene'].str.contains('ribosom', case=False)]
```

**Query**
```python
df.query('coluna < 0.05')
df.query('coluna > 8 and tipo < 6')
```

**Valores únicos**
```python
df['Amostra'].unique()                # lista
df['Amostra'].nunique()               # int
df['Amostra'].value_counts()
df['Amostra'].value_counts(normalize=True)
df['Amostra'].value_counts().to_dict()
```

**Ordenação**
```python
df.sort_values('LFQ', ascending=True)   # ou ascending=False
```

**Renomear / criar colunas**
```python
df.rename(columns={'old': 'new'})

df['log2FC'] = df['c1'] - df['c2']
df['sig'] = df['padj'] < 0.05
```

**Apply**
```python
df['gene'].apply(função)
```

**Strings**
```python
df['coluna'].str.strip()
df['coluna'].str.lower()
df['coluna'].str.split(';')
df['coluna'].str.contains('x')
df['coluna'].str.replace('x', 'y')
```

**Crosstab**
```python
pd.crosstab(df['Amostra'], df['Drug'])
#          Drug1  Drug2 ...
# Amostra1   freq   freq
# Amostra2   freq   freq
# equivalente a: df.groupby([...]).size().unstack()

pd.crosstab(df['A'], df['B'], normalize='index')
# margins=True   # adiciona totais de linha/coluna
```

**Rank**
```python
df.groupby('Amostra')['LFQ'].rank()
```

**Pivot table**
```python
df.pivot_table(index='gene', columns='Amostra', values='LFQ')
# gene  Am  LFQ            gene  V1   V2
# A     V1  100     ->     A     100  120
# A     V2  120            B     80   NaN
# B     V1  80
```

**Indexação — `.loc` vs `.iloc`**
```python
df.loc[linha, coluna]      # usa rótulos (nomes)
df.loc[:, 'coluna']
df.loc[df['coluna'] == 'a']

df.iloc[linha, coluna]     # usa índices (posição)
df.iloc[:, 0:3]
```

**Contas por linha**
```python
df[colunas].função(axis=1)

# soma
df['soma'] = df[colunas].sum(axis=1)

# média
df[colunas].mean(axis=1)
```

**Filtrar coluna por padrão (nome)**
```python
df.filter(like='LFQ', axis=1).columns
```

**Explode**
```python
df = df.explode('drug_class')
# x drug_class     ->   x drug
# bla [1,2]             bla 1
#                        bla 2
```

**Groupby**
```python
df.groupby(by='Amostra').size()                    # contagem
df.groupby('Amostra')['LFQ'].mean()
df.groupby(['Amostra', 'drug']).size()
#          A  d1  3
#             d2  4
#          B  d1  3
#             d2  5
```

**Reset index** — transforma o índice do groupby em coluna
```python
r = (df.groupby('Amostra')
       .size()
       .reset_index(name='count'))
# Amostra  count
# A        3
# B        4
```

**Pivot (via groupby + unstack)**
```python
(df.groupby(['Amostra', 'DC'])
   .size()
   .unstack(fill_value=0))   # preenche combinações faltantes com 0
```

**Merge**
```python
df = pd.merge(df1, df2, on='gene')
# how='left'

pd.concat([df1, df2])
```

**Drop**
```python
df.drop_duplicates()
df.drop_duplicates(subset='gene')   # duplicata considerando só essa coluna
```

**NaN**
```python
df.isna().sum()
df.dropna()
df.fillna(0)
```

**Filtrar top genes**
```python
df.nlargest(20, 'LFQ')
df.nsmallest(20, 'LFQ')
```

**Salvar**
```python
df.to_csv('nome.csv', index=False)
# sep='\t'  para tsv
```

**Dict comprehension**
```python
dict_novo = {key: value for (key, value) in iteration}
```

---

### 2.1.2 Complemento (o que não estava no caderno)

Filtros extras:
```python
# ~ nega a condição
df[~df['gene'].isin(['blaKPC'])]   # tudo MENOS blaKPC

# where / mask: mantém o shape, troca valor em vez de filtrar linha
df['LFQ'].where(df['LFQ'] > 0, other=0)   # negativo vira 0
```

Tipos e conversão:
```python
df['coluna'] = df['coluna'].astype(float)
df['coluna'] = pd.to_numeric(df['coluna'], errors='coerce')  # vira NaN se não converter
df['data'] = pd.to_datetime(df['data'])
```

Apply na linha inteira e map:
```python
# apply na linha inteira (axis=1) -> quando a função precisa de mais de uma coluna
df['risco'] = df.apply(lambda row: 'alto' if row['LFQ'] > 100 and row['p'] < 0.05 else 'baixo', axis=1)

# map: troca valores usando um dicionário (bom pra renomear categorias)
mapa = {'V1': 'Variante1', 'V2': 'Variante2'}
df['Amostra_nome'] = df['Amostra'].map(mapa)
```

Groupby avançado:
```python
# Múltiplas agregações de uma vez
df.groupby('Amostra')['LFQ'].agg(['mean', 'std', 'count'])

# Agregações diferentes por coluna
df.groupby('Amostra').agg({'LFQ': 'mean', 'p': 'min'})

# Nomeando a coluna resultante direto
df.groupby('Amostra').agg(LFQ_medio=('LFQ', 'mean'))

# transform: devolve o resultado no mesmo shape do df original (bom pra normalizar por grupo)
df['LFQ_norm'] = df['LFQ'] / df.groupby('Amostra')['LFQ'].transform('sum')
```

Merge com mais detalhe:
```python
# how: 'inner' (padrão, só o que casa), 'left', 'right', 'outer' (tudo)
pd.merge(df1, df2, on='gene', how='left')

# Quando o nome da coluna-chave é diferente nos dois dfs
pd.merge(df1, df2, left_on='gene_id', right_on='ARO', how='left')

# indicator=True: mostra de onde veio cada linha (útil pra debugar merge)
pd.merge(df1, df2, on='gene', how='outer', indicator=True)
```

Outros formatos de salvamento:
```python
df.to_excel('saida.xlsx', index=False)
df.to_parquet('saida.parquet')     # mais rápido e leve pra tabelas grandes (usado no ARGOS)
pd.read_parquet('saida.parquet')
```

</details>

<details>
<summary><h2>2.2 Numpy, Matplotlib e Seaborn</h2></summary>

### 2.2.1 Numpy — o essencial
```python
import numpy as np

arr = np.array([1, 2, 3, 4, 5])
arr.shape                       # dimensões
arr.mean(); arr.std(); arr.sum()
np.log2(arr)                    # bom pra fold-change
np.log10(arr + 1)               # +1 evita log(0)

# Arrays 2D (tipo uma matrix de presença/ausência)
matrix = np.zeros((5, 3))       # matriz de zeros 5x3
matrix = np.ones((5, 3))
np.where(arr > 2, 'alto', 'baixo')   # vetorizado, equivalente a apply(lambda) linha a linha

# Random (pra simulação/teste)
np.random.seed(42)              # reprodutibilidade
np.random.normal(0, 1, size=100)
```

### 2.2.2 Matplotlib — parâmetros completos por tipo de gráfico

Setup básico:
```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots(figsize=(8, 5), dpi=100)
# figsize=(largura, altura) em polegadas; dpi = resolução

ax.set_title('Título', fontsize=14)
ax.set_xlabel('Eixo X')
ax.set_ylabel('Eixo Y')
ax.legend(loc='best')           # 'upper right', 'lower left', 'best', etc.
plt.tight_layout()              # evita corte de labels
plt.savefig('figura.png', dpi=300, bbox_inches='tight')
plt.show()
```

**Scatter**
```python
ax.scatter(
    x, y,
    c=cores,              # cor por ponto (array numérico ou lista de cores)
    s=tamanhos,            # tamanho por ponto (array ou valor único)
    cmap='viridis',        # paleta, usada só se c for numérico
    alpha=0.7,             # transparência (0-1)
    edgecolors='black',
    linewidths=0.5,
    marker='o',            # 'o', 's', '^', 'x', 'D', etc.
)
```

**Bar**
```python
ax.bar(
    x, altura,
    width=0.8,
    color='steelblue',     # ou lista de cores, uma por barra
    edgecolor='black',
    linewidth=0.5,
    align='center',        # 'center' ou 'edge'
    yerr=erros,            # barra de erro (opcional)
    capsize=4,
)
```

**Line**
```python
ax.plot(
    x, y,
    color='crimson',
    linestyle='-',          # '-', '--', '-.', ':'
    linewidth=2,
    marker='o',
    markersize=5,
    label='LFQ médio',
)
```

**Boxplot**
```python
ax.boxplot(
    [grupo1, grupo2, grupo3],
    labels=['A', 'B', 'C'],
    showfliers=True,        # mostrar outliers
    patch_artist=True,      # permite colorir as caixas
)
```

**Heatmap "cru" (imshow)**
```python
im = ax.imshow(matrix, cmap='viridis', aspect='auto', vmin=0, vmax=1)
plt.colorbar(im, ax=ax, label='valor')
```

### 2.2.3 Seaborn — parâmetros completos por tipo de gráfico

Setup:
```python
import seaborn as sns
sns.set_theme(style='whitegrid')   # 'white', 'dark', 'darkgrid', 'ticks'
```

**Heatmap** (o mais usado no ARGOS)
```python
sns.heatmap(
    matrix,
    cmap='viridis',          # paleta (ver seção 2.2.4)
    annot=True,               # mostra o valor em cada célula
    fmt='.2f',                 # formato do número anotado
    linewidths=0.5,
    linecolor='white',
    vmin=0, vmax=1,             # limites da escala de cor
    cbar_kws={'label': 'valor'},
    square=False,
    xticklabels=True,
    yticklabels=True,
)
```

**Clustermap** (heatmap + dendrograma — equivalente ao `clustered_heatmap` do ARGOS)
```python
sns.clustermap(
    matrix,
    cmap='viridis',
    metric='jaccard',        # ou 'braycurtis', 'euclidean'...
    method='average',         # linkage: 'average', 'complete', 'ward'
    row_cluster=True,
    col_cluster=True,
    figsize=(10, 10),
    annot=False,
)
```

**Barplot / Boxplot / Violinplot**
```python
sns.barplot(data=df, x='Amostra', y='LFQ', hue='drug_class', palette='Set2', errorbar='sd')
sns.boxplot(data=df, x='Amostra', y='LFQ', hue='tipo', palette='pastel')
sns.violinplot(data=df, x='Amostra', y='LFQ', palette='muted', inner='quartile')
```

**Scatterplot**
```python
sns.scatterplot(
    data=df, x='logFC', y='-log10(p)',
    hue='sig',               # colore por categoria
    style='drug_class',       # muda o marcador por categoria
    size='LFQ',                # tamanho do ponto por valor
    palette='coolwarm',
    alpha=0.7,
)
```

**Pairplot** (bom pra EDA — ver seção 2.4)
```python
sns.pairplot(df, hue='tipo', palette='husl', diag_kind='kde')
```

### 2.2.4 Paletas de cores prontas
```python
# Contínuas / sequenciais (valores numéricos, ex: heatmap, LFQ)
'viridis'      # padrão robusto, perceptualmente uniforme
'magma' / 'inferno' / 'plasma'   # variações escuro->claro
'Blues' / 'Greens' / 'Reds'       # sequenciais de uma cor só

# Divergentes (valores com ponto central, ex: log2FC, correlação)
'coolwarm'
'RdBu_r'       # vermelho-azul, invertido pra vermelho = positivo
'vlag'

# Categóricas (grupos discretos, ex: Amostra, drug_class)
'Set1' / 'Set2' / 'Set3'
'tab10' / 'tab20'
'husl'         # cores igualmente espaçadas, boa quando tem muitas categorias
'pastel' / 'muted' / 'deep' / 'bright'   # variações de saturação do seaborn

# Definir manualmente (quando quer controlar cor exata por grupo)
paleta_manual = {'clinico': '#d62728', 'ambiental': '#2ca02c'}
sns.boxplot(data=df, x='tipo', y='LFQ', palette=paleta_manual)
```

</details>

<details>
<summary><h2>2.3 Funções — estruturando algo complexo em várias funções</h2></summary>

> Ideia central: uma função = uma responsabilidade. Se você descreve o que a função
> faz e precisa usar "e" no meio da frase, provavelmente ela devia ser duas funções.

### 2.3.1 Anatomia básica
```python
def calcular_media(valores: list[float]) -> float:
    """Calcula a média de uma lista de valores."""
    return sum(valores) / len(valores)

# type hints (valores: list[float], -> float) não são obrigatórios, mas ajudam
# a documentar o que a função espera e retorna sem precisar ler o corpo inteiro
```

### 2.3.2 Argumentos: posicionais, default e keyword-only
```python
def plot_heatmap(df, drug_class=None, cmap='viridis', *, cluster=False):
    # df, drug_class: podem ser passados por posição ou nome
    # cmap='viridis': valor default, não precisa passar se não quiser mudar
    # * antes de cluster: tudo depois só pode ser passado por nome (cluster=True)
    #   -> útil quando a função tem muitos parâmetros e você quer forçar clareza
    #      na chamada (evita plot_heatmap(df, None, 'viridis', True) ilegível)
    ...

plot_heatmap(df, cluster=True)          # ok
# plot_heatmap(df, None, 'viridis', True)  # funcionaria, mas ilegível
```

### 2.3.3 Quebrando um problema complexo em várias funções
Exemplo no espírito do que o `plot_heatmap` do ARGOS faz: uma função "pública" que
orquestra, e funções internas menores que cada uma resolve uma parte.

```python
def plot_heatmap(dataset, drug_class=None, cluster=False, **kwargs):
    """Função pública: valida entrada, decide o caminho e delega."""
    matrix = _prepare_matrix(dataset, drug_class)

    if cluster:
        return _clustered_heatmap(matrix, **kwargs)
    else:
        return _render_heatmap(matrix, **kwargs)


def _prepare_matrix(dataset, drug_class):
    """Só prepara os dados: filtra e pivota. Não sabe nada de plot."""
    df = dataset.full_resistoma
    if drug_class is not None:
        df = df[df['drug_class'] == drug_class]
    return df.pivot_table(index='gene', columns='Amostra', values='count', fill_value=0)


def _render_heatmap(matrix, **kwargs):
    """Só sabe desenhar um heatmap simples. Não sabe de onde veio a matrix."""
    ...


def _clustered_heatmap(matrix, **kwargs):
    """Só sabe calcular distância (Jaccard/Bray-Curtis) e clusterizar."""
    ...
```

Por que separar assim:
- `_prepare_matrix` pode ser testada sozinha, sem precisar gerar nenhum gráfico.
- Se um bug aparece só no modo `cluster=True`, você sabe exatamente onde olhar.
- Funções com `_` na frente (convenção, não regra do Python) sinalizam "uso interno,
  não é pra ser chamada de fora do módulo".
- `**kwargs`: junta argumentos extras num dicionário e repassa pra frente sem
  precisar listar cada um — útil quando a função de baixo nível tem parâmetros
  de estilo (cor, tamanho da figura, etc.) que a de cima só quer repassar.

### 2.3.4 Regra prática pra decidir quando quebrar em mais funções
```python
# Sinais de que já passou do ponto de quebrar:
# - função tem mais de ~30-40 linhas
# - você usa comentários tipo "### agora fazemos X" pra separar blocos dentro dela
#   -> cada bloco comentado é candidato a virar uma função
# - você repete o mesmo trecho de código em dois lugares diferentes
# - pra testar uma parte pequena, você precisa rodar a função inteira
```

### 2.3.5 Docstrings e erro explícito (bom hábito pra funções reutilizáveis)
```python
def load_rgi_output(path: str) -> pd.DataFrame:
    """
    Lê o output do RGI (CARD) e retorna um DataFrame padronizado.

    Parameters
    ----------
    path : str
        Caminho pro arquivo .txt de saída do RGI.

    Returns
    -------
    pd.DataFrame
        Tabela com colunas renomeadas e tipos ajustados.
    """
    if not Path(path).exists():
        raise FileNotFoundError(f"Arquivo não encontrado: {path}")

    df = pd.read_csv(path, sep='\t')
    return df
```

</details>

<details>
<summary><h2>2.4 Dict e List Comprehension</h2></summary>

### 2.4.1 List comprehension — sintaxe
```python
# forma tradicional
lista = []
for x in range(10):
    if x % 2 == 0:
        lista.append(x * 2)

# comprehension equivalente
lista = [x * 2 for x in range(10) if x % 2 == 0]
#         ^valor   ^iteração        ^filtro (opcional)
```

### 2.4.2 Dict comprehension — sintaxe (já estava no caderno)
```python
dict_novo = {chave: valor for (chave, valor) in iteravel}

# Exemplo: inverter um dicionário (valor vira chave)
mapa = {'V1': 'Variante1', 'V2': 'Variante2'}
mapa_invertido = {v: k for k, v in mapa.items()}
# {'Variante1': 'V1', 'Variante2': 'V2'}
```

### 2.4.3 Onde isso aparece de fato no ARGOS
```python
# Contar quantos genes caem em cada Rank (arg_ranker), a partir da tabela de lookup
# Em vez de um loop com if/elif pra cada Rank:
contagem_por_rank = {
    rank: (df['Rank'] == rank).sum()
    for rank in df['Rank'].unique()
}

# Montar um dicionário sample -> caminho do arquivo de output, pra iterar no update()
arquivos_por_sample = {
    sample: Path(pasta_resultados) / f"{sample}_rgi.txt"
    for sample in lista_samples
}

# Filtrar genes de risco alto (Rank I) já achatados numa lista, a partir do dataset
genes_rank1 = [
    gene for gene in dataset.full_resistoma['gene']
    if rank_lookup.get(gene) == 'Rank I'
]

# Combinando comprehension com o padrão de "matriz na granularidade mais fina":
# construir o dict de renomeação gene_clean -> nome ARO cru, aplicado só na hora
# de plotar (groupby), sem alterar a matriz original
gene_clean_map = {
    aro: aro.split('_')[0]
    for aro in dataset.full_resistoma['gene'].unique()
}
```

### 2.4.4 Comprehension aninhada — cuidado com legibilidade
```python
# Achatando uma lista de listas (ex: genes por amostra -> lista única de genes)
genes_por_amostra = [['blaKPC', 'blaNDM'], ['blaOXA'], ['blaKPC']]
todos_genes = [gene for sublist in genes_por_amostra for gene in sublist]
# ['blaKPC', 'blaNDM', 'blaOXA', 'blaKPC']

# Regra prática: se a comprehension passa de ~2 níveis (2 "for") ou fica difícil
# de ler numa linha, é melhor voltar pro loop tradicional — comprehension é
# sobre legibilidade, não sobre economizar linhas.
```

### 2.4.5 Set comprehension (bônus — pra valores únicos)
```python
genes_unicos = {gene for sublist in genes_por_amostra for gene in sublist}
# {'blaKPC', 'blaNDM', 'blaOXA'}  -> sem repetição, sem ordem garantida
```

</details>

<details>
<summary><h2>2.5 Typer — CLI (alternativa mais moderna ao argparse)</h2></summary>

> `pip install typer`. Usa type hints da função pra gerar o parser automaticamente
> — menos código repetido que argparse pra CLIs simples.

### 2.5.1 Básico
```python
import typer

app = typer.Typer()

@app.command()
def saudacao(nome: str, vezes: int = 2):
    """Imprime uma saudação `vezes` vezes."""
    for _ in range(vezes):
        typer.echo(f"Olá, {nome}!")

if __name__ == "__main__":
    app()
```
```bash
python script.py rodrigo            # usa o default vezes=2
python script.py rodrigo --vezes 1
python script.py --help             # help gerado automaticamente
```

### 2.5.2 Argumento opcional com `Optional` e flags booleanas
```python
from typing import Optional
import typer

app = typer.Typer()

@app.command()
def processar(
    arquivo: str,
    saida: Optional[str] = None,     # opcional, default None
    verbose: bool = False,           # vira flag: --verbose / --no-verbose
):
    saida = saida or f"{arquivo}_processado.csv"
    if verbose:
        typer.echo(f"Processando {arquivo} -> {saida}")
    ...
```
```bash
python script.py dados.csv --verbose
python script.py dados.csv --saida final.csv
```

### 2.5.3 Múltiplos comandos no mesmo app (bom pra CLI de pipeline/toolkit)
```python
import typer

app = typer.Typer()

@app.command()
def rodar(sample: str):
    """Roda a análise pra uma amostra."""
    typer.echo(f"Rodando {sample}")

@app.command()
def status(sample: str):
    """Checa o status de uma amostra já processada."""
    typer.echo(f"Status de {sample}: ok")

if __name__ == "__main__":
    app()
```
```bash
python script.py rodar MAF1
python script.py status MAF1
python script.py --help          # lista os dois comandos
python script.py rodar --help    # help específico do comando
```

### 2.5.4 Validação e choices (equivalente ao `choices=` do argparse)
```python
from enum import Enum
import typer

class Formato(str, Enum):
    csv = "csv"
    tsv = "tsv"
    parquet = "parquet"

@app.command()
def exportar(arquivo: str, formato: Formato = Formato.csv):
    typer.echo(f"Exportando como {formato.value}")
```
```bash
python script.py exportar dados        # usa csv (default)
python script.py exportar dados --formato parquet
python script.py exportar dados --formato xml   # erro: não é uma opção válida
```

### 2.5.5 Path como tipo (valida e converte automaticamente)
```python
from pathlib import Path
import typer

@app.command()
def carregar(arquivo: Path):
    if not arquivo.exists():
        typer.echo(f"Arquivo não encontrado: {arquivo}", err=True)
        raise typer.Exit(code=1)
    typer.echo(f"Carregando {arquivo}")
```

</details>

<details>
<summary><h2>2.6 Python essenciais (argparse + pathlib, do zip)</h2></summary>

> Consolidado de `python/argparse.py` e `python/pathlib.py`. `argparse` é a
> alternativa mais antiga/verbosa ao typer (seção 2.5) — útil saber ler, mesmo
> usando typer pra escrever CLIs novas.

### 2.6.1 argparse — básico
```python
import argparse

parser = argparse.ArgumentParser()

# Argumento posicional (obrigatório, sem --)
parser.add_argument('greeting', type=str, help='The greeting message to display')

# Argumento opcional (com -- ou -)
parser.add_argument('-t', '--times', type=int, help='Number of times to display the greeting')
parser.set_defaults(times=2)

args = parser.parse_args()

for i in range(args.times):
    print(args.greeting)
```
```bash
python teste_arg.py oi
# oi
# oi
python teste_arg.py oi -t 1
# oi
```

### 2.6.2 argparse — choices (restringir valores aceitos)
```python
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('greeting', type=str, help='The greeting message to display')
parser.add_argument('-l', '--language', type=str, choices=['en', 'pt'], help='Language of the greeting')
parser.set_defaults(language='pt')

args = parser.parse_args()

for i in range(args.times):
    if args.language == 'pt':
        print(f"Olá! {args.greeting}")
    else:
        print(f"Hello! {args.greeting}")
```
```bash
python teste_arg.py rodrigo
# Olá! rodrigo
python teste_arg.py rodrigo -l en
# Hello! rodrigo
```

### 2.6.3 pathlib — manipulação de caminhos
```python
from pathlib import Path

# Diretório atual
print(Path.cwd())

# Listar tudo no diretório atual
for p in Path().iterdir():
    print(p)

### Manipulando partes do caminho
script = Path("teste_arg.py")
print(script.suffix)   # .py -> só a extensão
print(script.stem)     # teste_arg -> nome sem extensão
print(script.parent)   # . -> diretório pai

### Criar diretório e arquivo
new_dir = Path("diretorio_1")
new_dir.mkdir(exist_ok=True)          # não dá erro se já existir

new_file = new_dir / "novo_arquivo.txt"
print(new_file.absolute())
new_file.touch(exist_ok=True)

### Caminhos relativos, absolutos e home
Path("..").absolute()      # caminho absoluto sem resolver ".."
Path("..").resolve()       # resolve ".." e links simbólicos
Path(__file__).resolve()   # caminho absoluto do próprio script
Path.home()                # diretório home do usuário

### Glob — buscar arquivos por padrão
for p in Path().glob("*.py"):     # só no diretório atual
    print(p)

for p in Path().rglob("*.py"):    # recursivo (subpastas também)
    print(p)

### Ler e escrever arquivos
arquivo = Path.home() / "testes/teste_arg.py"
with arquivo.open() as f:
    print(f.read())
```

</details>

<details>
<summary><h2>2.7 Análise Exploratória de Dados (EDA)</h2></summary>

### 2.7.1 Roteiro mínimo só com pandas/seaborn (sem instalar nada novo)
```python
df.shape                       # (linhas, colunas)
df.info()                      # tipos + quantos non-null por coluna
df.describe(include='all')     # estatísticas (numéricas e categóricas)
df.isna().sum().sort_values(ascending=False)   # onde estão os NaN
df.nunique()                   # cardinalidade de cada coluna (detecta ID vs categoria)

# Correlação entre variáveis numéricas
sns.heatmap(df.corr(numeric_only=True), cmap='coolwarm', annot=True, center=0)

# Distribuição de cada variável numérica de uma vez
df.hist(figsize=(12, 8), bins=30)

# Relação entre pares de variáveis, colorido por categoria
sns.pairplot(df, hue='tipo', palette='husl')

# Duplicatas
df.duplicated().sum()
```

### 2.7.2 Bibliotecas que fazem o relatório automático
Quando quer um overview rápido sem escrever tudo isso na mão:

- **ydata-profiling** (antigo `pandas-profiling`) — o mais completo: gera um HTML
  com distribuição, correlação, valores faltantes, alertas de qualidade (colunas
  constantes, alta cardinalidade, correlação alta entre pares) pra cada coluna.
  ```python
  from ydata_profiling import ProfileReport
  profile = ProfileReport(df, title="EDA", minimal=False)
  profile.to_file("eda_report.html")
  ```
  `minimal=True` deixa mais rápido em datasets grandes (pula algumas correlações caras).

- **sweetviz** — parecido, mais rápido de gerar, bom pra comparar dois datasets lado
  a lado (ex: treino vs teste, ou clínico vs ambiental).
  ```python
  import sweetviz as sv
  report = sv.compare([df_clinico, "Clínico"], [df_ambiental, "Ambiental"])
  report.show_html("comparacao.html")
  ```

- **missingno** — visualização específica pra padrão de dados faltantes (matriz,
  barra, dendrograma de correlação entre ausências). Útil quando o NaN não é
  aleatório (ex: um gene só é reportado se passou de um threshold).
  ```python
  import missingno as msno
  msno.matrix(df)
  msno.heatmap(df)   # correlação entre "faltar" em uma coluna e faltar em outra
  ```

### 2.7.3 Recomendação prática
Pra uma checagem rápida do dia a dia (ex: conferir uma tabela nova do RGI/CARD
antes de meter no pipeline): `df.info()` + `df.describe()` + `df.isna().sum()`
já resolve. Pra um relatório que vai ser revisado por outra pessoa (banca,
supervisor) ou quando o dataset é novo e desconhecido: vale rodar `ydata-profiling`
uma vez e olhar os alertas — ele aponta coisas que passariam despercebidas
(coluna quase toda igual, dois campos muito correlacionados, outlier extremo).

</details>

</details>

---

<a name="links-uteis"></a>
<details>
<summary><h1>🔗 Links Úteis</h1></summary>

- Metagenomics workshop - https://denbi-simplevm-metagenomics-workshop.readthedocs.io/en/latest/index.html
- Computational Genomics with R - https://compgenomr.github.io/book/
- Conceitos estatísticos - https://zoehlerbz.medium.com
- Curso DEseq - https://colab.research.google.com/drive/1cjsBESHsHwzFy2-92FZR82-bMkBWiCkk#scrollTo=JEiG9lHo7Ie-
- Curso R (introdução) - https://wapsyed.github.io/cursor/#sobre-o-curso
- Conda cheatsheet - https://docs.conda.io/projects/conda/en/latest/_downloads/843d9e0198f2a193a3484886fa28163c/conda-cheatsheet.pdf
- CS50's Introduction to Programming with Python - https://cs50.harvard.edu/python/

</details>
