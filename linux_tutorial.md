# LINUX #
Author: Rodrigo Lusa (lusarodrigo4@gmail.com)
Date: 07/31/2025

> SHELL (or command line, terminal) is a way to interface with the operating system and run commands.

Basico
```bash
ls                            # Lista os arquivos e diretórios do diretório atual
ls -l                         # Lista detalhada dos arquivos e diretórios (permissões, tamanho, data, etc.)
ls -lh                        # Lista detalhada com tamanhos legíveis (K, M, G)
pwd                           # Mostra o caminho completo do diretório atual
cd pasta                      # Entra na pasta chamada "pasta"
cd ..                         # Volta para o diretório anterior
clear                         # Limpa a tela do terminal
mkdir nova_pasta              # Cria um diretório chamado "nova_pasta"
rmdir pasta_vazia             # Remove um diretório vazio chamado "pasta_vazia"
rm arquivo.txt                # Remove o arquivo chamado "arquivo.txt"
rm -r pasta                   # Remove a pasta "pasta" e todo o seu conteúdo
nano arquivo.txt              # Abre o editor nano para criar ou editar "arquivo.txt"
less arquivo.txt              # Mostra o conteúdo de "arquivo.txt" página por página ("q" sai do less, "/palavra" procura pela palavra)
mv arquivo.txt nova_pasta/    # Move "arquivo.txt" para dentro de "nova_pasta/"
mv arquivo.txt novo_nome.txt  # Renomeia "arquivo.txt" para "novo_nome.txt"
echo "Olá, mundo!"            # Imprime "Olá, mundo!" na tela
```

Redirecionando arquivos
```bash
echo "Olá, mundo!" > saudacao.txt             # Redirecionar saída para um arquivo (sobrescreve o arquivo)
echo "Mais uma linha" >> saudacao.txt         # Redirecionar saída para um arquivo (adiciona ao final / append)

cat < saudacao.txt                            # Redirecionar entrada de um arquivo para um comando
cat saudacao.txt | grep Olá                   # Pipe: envia a saída de um comando como entrada para outro
cat arquivo1.txt arquivo2.txt > combinado.txt # Combinar arquivos em um só
cat saudacao.txt                              # Exibir o conteúdo de um arquivo com cat

sort nomes.txt                                # Ordenar um arquivo (ordem alfabética padrão)
-f   #Ignorar maiúsculas/minúscula
-n   #Ordena numericamente
-r   #Ordem reveresa
-k 3 #Ordena pelo campo 3

cut nomes.txt                                 # Extrair partes do texto
-c   #cuts the specified list of characters
-f   #cuts the specified list of fields
-d   #can change the delimiting character
cut -d" " -f10 

wc file.txt # Word Count -> newline, words, bytes

grep "^>" arquivo.fasta                       # "Control F"
-i, --ignore-case:  #Ignores case distinctions in both the pattern and the input data, allowing for case-insensitive searches.
-v, --invert-match: #Selects lines that do not match the specified pattern, effectively inverting the search.
-n, --line-number:  #Prefixes each matching line with its corresponding line number in the input file.
-c, --count:        #Suppresses normal output and instead prints only a count of the number of matching lines.

tr                                           # Character-level manipulation (translate, delete...)
echo "hello" | tr 'hl' 'HL'             #substitui hl por HL  ->  HeLLo
echo "my ID is 73535" | tr -d [:digit:] #-d delete all digits ->  my ID is 
echo "aaabbbccc" | tr -s 'abc'          #-s squeeze           ->  abc
```

# PATH and aliases
PATH is a shell variable
```bash
# It is a colon-separated list of directories in which the shell looks for commands
$ echo $PATH
/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin
```

Alias is a keyboard shortcut
```bash
alias lm="ls -l | more"
```

Como rodar um script proprio?
```bash
# Mover um script para o $PATH para poder usa-lo mais facilmente:
sudo mv script /usr/local/bin

# Usar o caminho completo
./script #ou /home/lusa/script

# Criar um /bin no seu diretorio padrao, para guardar os scripts e adicionar ao $PATH
mkdir /bin
PATH=$PATH:~/bin
echo $PATH
# mas assim todas as vezes que fechar o terminal, precisamos colocar de novo o caminho
```

Adicionar comandos permanentemente no `~/.bashrc`:
```bash
nano ~/.bashrc

#Adiciona $SCRATCH/bin (/scratch/y/yanwang/lusaro/bin) no $PATH
export PATH=$SCRATCH/bin:$PATH

#Adiciona os caminhos Appteiner
alias busco="apptainer exec --bind=$SCRATCH /scratch/lusaro/bin/busco_6.0.0.sif busco"
alias eukcc="apptainer exec --bind=$SCRATCH /lusaro/bin/eukcc_latest.sif eukcc"

# Depois de adicionar, rode
source ~/.bashrc

# Tentar comando "apptainer exec --bind=$SCRATCH /scratch/y/yanwang/lusaro/bin/busco_6.0.0.sif busco"x
busco --help 
```
# Trillium
Large parallel cluster built by Lenovo Canada and hosted by SciNet at the University of Toronto.

* /home – For personal files and configurations.
* /scratch – High-speed, temporary storage for job data.
* /project – Shared storage for project teams and collaborations.

```bash
# Entrar no sistema
ssh -i ~/.ssh/ssh_key lusaro@trillium.alliancecan.ca

# Copiar arquivos do sistema para o computador local
scp -i ~/.ssh/ssh_key lusaro@trillium.alliancecan.ca:/scratch/lusaro/arquivo .
    #-r se for pasta
```

Trillium uses the environment modules system to manage compilers, libraries, and other software packages
```bash
module load <module-name> #Load the default version of a software package.
module purge              #Unload all currently loaded modules.
module avail              #List available modules that can be loaded.
module list               #Show currently loaded modules.
module spider             #Search for available modules and their versions.
```

Script basico para submeter Job:
```bash
#!/bin/sh
#SBATCH -J NOME_DO_JOB
#SBATCH --time=3:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --nodes=1

cd $SLURM_SUBMIT_DIR

module load CCEnv nixpkgs/16.09

parallel -j $SLURM_TASKS_PER_NODE <<EOF #opcional. Apenas para scripts em paralelo

<commands>

EOF
```

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