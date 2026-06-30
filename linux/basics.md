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
