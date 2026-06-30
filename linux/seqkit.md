# Manipular arquivos FASTA e FASTQ
1. seqkit
```bash
# Estatísticas gerais
seqkit stats file.fa

# Manipular o arquivo de forma geral
seqkit seq [flags] 
-n, --name                  #only print names/sequence headers
-r, --reverse               #reverse sequence
-s, --seq                   #only print sequences
-g, --remove-gaps           #remove gaps letters
-i, --only-id               #print IDs instead of full headers
-M, --max-len               #only print sequences <= the maximum length (-1 forno limit)
-m, --min-len               #only print sequences >= the minimum length (-1 for no limit)
seqkit seq -m 100 -M 1000   #sequences between 100 (-m) and 1000 (-M) 

# Get subsequences by region/gtf/bed, including flanking sequences
seqkit subseq [flags] 
-u, --up-stream         #up stream length
-d, --down-stream       #down stream length
-f, --only-flank        #only return up/down stream sequence
-r, --region            #by region. e.g 1:12 for first 12 bases/  -12:-1 for last 12 bases/ 13:-1 for cutting first 12 bases

# Search sequences by ID/name/sequence/sequence motifs
seqkit grep [flags]
-n, --by-name               #match by full name instead of just ID
-s, --by-seq                #search subseq on seq
-C, --count                 #just print a count of matching records. with the -v , count non-matching records
-i, --ignore-case           #ignore case
-v, --invert-match          #invert 
-m, --max-mismatch          #max mismatch when matching by seq
-p, --pattern               #search pattern (multiple values supported)
-f, --pattern-file          #pattern file (one record per line)
-r, --use-regexp            #patterns are regular expression

seqkit grep -p "contig_name" file.fa          
seqkit grep -f list.txt file.fa 
seqkit grep -n -f name.txt file.fa
```

2. Comandos basicos:
```bash
# Contar quantas sequências existem em um arquivo FASTA
cat arquivo.fasta | grep ">" | wc -l
grep -c "^>" arquivo.fasta      #^ indica início da linha

# Mostrar apenas os nomes das sequências de um arquivo FASTA
cat arquivo.fasta | grep ">" | cut -f1
grep "^>" arquivo.fasta | cut -c2-

# Contar quantas reads existem em um arquivo FASTQ
cat reads.fq | grep "@" | wc -l

# Listar apenas as sequências (sem os headers) de um arquivo FASTA
cat arquivo.fasta | grep -v ">"
grep -v "^>" arquivo.fasta

# Encontrar todas as sequências que contêm um determinado padrão (ex: ATG)
cat arquivo.fasta | grep -w "ATG"

# Contar o número total de bases (A, T, G ou C) em um arquivo FASTA
grep -v ">" arquivo.fasta | tr -d '\n' | wc -c

# Extrair todas as reads de um arquivo FASTQ que contenham "N" na sequência
cat reads.fq | grep "N"
grep -A1 "^@" reads.fq | grep "N"     #-A1: mostra a linha encontrada + 1 linha "after"

# Ordenar os headers de um arquivo FASTA em ordem alfabética
grep "^>" arquivo.fasta | sort

# Contar quantas sequências começam com "ATG" em um arquivo FASTA
grep -v "^>" arquivo.fasta | grep "^ATG" | wc -l
```
