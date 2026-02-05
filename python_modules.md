# KIT de bibliotecas (modules) para automação de Bioinformática
- pandas
- argparse
- pathlib
- subprocess
- logging
- json / yaml

Para programar em `python` usando o VSCode, posso abrir pelo icone ou digitar `code .` na minha pasta atual.
Para abrir o terminal direto do VSCode: `Ctrl + (crase)`.

## argparse
```{python}
import argparse

#####
# Criando o parser de argumentos
parser = argparse.ArgumentParser()

#####
# Adicionando um argumento posicional
# add_argument(nome, tipo, mensagem de ajuda se digitar --help)
parser.add_argument('greeting', type=str, help='The greeting message to display')

# Adicionando um argumento opcional
parser.add_argument('-t', '--times', type=int, help='Number of times to display the greeting')

# Definindo valor padrão para o argumento opcional
parser.set_defaults(times=2)

#####
# Le argumentos da linha de comando
args = parser.parse_args()

for i in range(args.times):
    print(args.greeting)
```
Linha de comando e retornos
```{text}
python teste_arg.py oi
oi
oi
python teste_arg.py oi -t 1
oi
```
Agora, adicionando flags opcionais com escolhas
```{python}
import argparse

#####
# Criando o parser de argumentos
parser = argparse.ArgumentParser()

#####
# Adicionando um argumento posicional
# add_argument(nome, tipo, mensagem de ajuda se digitar --help)
parser.add_argument('greeting', type=str, help='The greeting message to display')

# Adicionando escolhas para um argumento
parser.add_argument('-l', '--language', type=str, choices=['en', 'pt'], help='Language of the greeting')
parser.set_defaults(language='pt')

#####
# Le argumentos da linha de comando
args = parser.parse_args()

for i in range(args.times):
    if args.language == 'pt':
        print(f"Olá! {args.greeting}")
    else:
        print(f"Hello! {args.greeting}")
```
Linha de comando e retornos
```{text}
python teste_arg.py rodrigo
Olá! rodrigo
python teste_arg.py rodrigo -l en
Hello! rodrigo
```

### DESAFIO — “Read Inspector CLI”
Obhetivo:
- Receber uma pasta com arquivos FASTQ
- Iterar por todos os arquivos da pasta
Para cada arquivo:
- contar quantos reads existem
- mostrar o nome do arquivo
- mostrar o total de arquivos analisados
- mostrar o total de reads somados
