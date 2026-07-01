# FIND - Cheat Sheet para Bioinformática

## Sintaxe Geral

```bash
find [onde_procurar] [testes] [ações]
```

Exemplo:

```bash
find . -type f -name "*.txt"
```

Interpretação:

* `.` → procurar a partir daqui
* `-type f` → apenas arquivos
* `-name "*.txt"` → arquivos terminados em `.txt`

---

# Conceito Fundamental

Pense sempre:

```bash
find ONDE TESTES AÇÕES
```

Exemplo:

```bash
find . -type f -name "*.fastq.gz" -print
```

---

# Procurar por Nome

## Todos os TXT

```bash
find . -name "*.txt"
```

## Ignorando maiúsculas/minúsculas

```bash
find . -iname "*.txt"
```

Meu exemplo:

```bash
find . -name "*.tsv"
```

---

# Procurar por Caminho Completo

Quando você precisa procurar usando partes do caminho.

## Todos os resultados dentro de uma pasta chamada results

```bash
find . -path "*/results/*.txt"
```

## Seu exemplo

```bash
find . -path "*/final_resistome.tsv"
```

Resultado:

```text
./atlantic_florest/MAF3/resistome/07_final/final_resistome.tsv
./atlantic_florest/MAF1/resistome/07_final/final_resistome.tsv
./atlantic_florest/MAF2/resistome/07_final/final_resistome.tsv
```

---

# Apenas Arquivos

```bash
find . -type f
```

---

# Apenas Diretórios

```bash
find . -type d
```

---

# Contagem

## Quantos arquivos existem?

```bash
find . -type f | wc -l
```

## Quantos TSV existem?

```bash
find . -name "*.tsv" | wc -l
```

Meu exemplo:

```bash
find atlantic_florest -name "*.fa" | wc -l
```


---

# Tempo

## Modificados nas últimas 24 horas

```bash
find . -mtime 0
```

## Modificados nos últimos 7 dias

```bash
find . -mtime -7
```

## Modificados há mais de 30 dias

```bash
find . -mtime +30
```

---

# Arquivos Vazios

```bash
find . -empty
```

---

# Permissões

## Arquivos executáveis

```bash
find . -executable
```

## Arquivos graváveis

```bash
find . -writable
```

---

# Copiar Arquivos

## Um por vez

```bash
find . -name "*.txt" -exec cp {} backup/ \;
```

## Forma mais eficiente

```bash
find . -name "*.txt" -exec cp -t backup {} +
```

---

# Renomear Arquivos

## Adicionar prefixo

```bash
find backup/ -name "*.tsv" \
-exec bash -c '
mv "$1" "$(dirname "$1")/OLD_$(basename "$1")"
' _ {} \;
```

Antes:

```text
backup/final_resistome.tsv
```

Depois:

```text
backup/OLD_final_resistome.tsv
```

---

## Adicionar sufixo

```bash
find . -name "*.txt" \
-exec bash -c '
mv "$1" "${1%.txt}_BACKUP.txt"
' _ {} \;
```

Resultado:

```text
arquivo.txt
```

↓

```text
arquivo_BACKUP.txt
```

---

## Trocar extensão

```bash
find . -name "*.txt" \
-exec bash -c '
mv "$1" "${1%.txt}.csv"
' _ {} \;
```

---

# Operadores Lógicos

## AND

```bash
find . -type f -name "*.txt"
```

equivale a:

```bash
find . -type f -a -name "*.txt"
```

---

## OR

```bash
find . \( -name "*.txt" -o -name "*.csv" \)
```

---

## NOT

```bash
find . ! -name "*.txt"
```

---

# -printf

A manpage mostra que:

```bash
%p
```

= caminho completo

```bash
%f
```

= apenas nome do arquivo

```bash
%h
```

= diretório pai

```bash
%P
```

= remove o ponto inicial (`./`)

---

## Exemplo

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n"
```

Saída:

```text
atlantic_florest/MAF3/resistome/07_final/final_resistome.tsv
atlantic_florest/MAF1/resistome/07_final/final_resistome.tsv
atlantic_florest/MAF2/resistome/07_final/final_resistome.tsv
```

---

# Extraindo Campos com cut

## Primeiro campo

```bash
find . -path "*/final_resistome.tsv" \
-print0 | tr '\0' '\n' | cut -d/ -f1
```

Resultado:

```text
atlantic_florest
```

---

## Segundo campo

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" | cut -d/ -f2
```

Resultado:

```text
MAF3
MAF1
MAF2
```

---

## Dois primeiros campos

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" | cut -d/ -f-2
```

Resultado:

```text
atlantic_florest/MAF3
atlantic_florest/MAF1
atlantic_florest/MAF2
```

---

# Quando Quero Contar de Trás para Frente

O cut NÃO faz isso.

Use:

```bash
rev
```

---

## Último campo

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" \
| rev | cut -d/ -f1 | rev
```

Resultado:

```text
final_resistome.tsv
```

---

## Penúltimo campo

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" \
| rev | cut -d/ -f2 | rev
```

Resultado:

```text
07_final
```

---

## Terceiro a partir do final

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" \
| rev | cut -d/ -f3 | rev
```

Resultado:

```text
resistome
```

---

## Quarto a partir do final

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" \
| rev | cut -d/ -f4 | rev
```

Resultado:

```text
MAF3
MAF1
MAF2
```

---

# Método Melhor: awk

## Último campo

```bash
awk -F/ '{print $NF}'
```

## Penúltimo campo

```bash
awk -F/ '{print $(NF-1)}'
```

## Terceiro a partir do final

```bash
awk -F/ '{print $(NF-2)}'
```

## Quarto a partir do final

```bash
awk -F/ '{print $(NF-3)}'
```

Exemplo:

```bash
find . -path "*/final_resistome.tsv" -printf "%P\n" \
| awk -F/ '{print $(NF-3)}'
```

Resultado:

```text
MAF3
MAF1
MAF2
```

---

# Resumo Mental

| Quero              | Comando                   |
| ------------------ | ------------------------- |
| Nome do arquivo    | -name                     |
| Caminho completo   | -path                     |
| Apenas arquivos    | -type f                   |
| Apenas diretórios  | -type d                   |
| Tamanho            | -size                     |
| Tempo              | -mtime                    |
| Profundidade       | -maxdepth                 |
| Executar comando   | -exec                     |
| Imprimir caminho   | -print                    |
| Imprimir formatado | -printf                   |
| Remover ./         | %P                        |
| Último campo       | awk -F/ '{print $NF}'     |
| Penúltimo campo    | awk -F/ '{print $(NF-1)}' |
| Contar resultados  | wc -l                     |
| Operador AND       | -a                        |
| Operador OR        | -o                        |
| Operador NOT       | !                         |

```
```
