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

## Pathlib
```{python}
from pathlib import Path

# Current working directory
print(Path.cwd()) 

# List all items in the current directory
for p in Path().iterdir():
    print(p)

### Manipulating paths
script_argparse = Path("teste_arg.py")
print(script_argparse)
print(script_argparse.suffix) #só o sufixo (.py)
print(script_argparse.stem)   #só o nome do arquivo sem o sufixo (teste_arg)
print(script_argparse.parent) #o diretório pai (.) nesse caso, pois o arquivo está no diretório atual


### Criating a new directory
new_dir = Path("diretorio_1")
new_dir.mkdir(exist_ok=True)  # Cria o diretório, se não existir


# Criando um novo arquivo dentro do novo diretório
new_file = new_dir / "novo_arquivo.txt"
print(new_file)
print(new_file.parent)  # O diretório pai do novo arquivo (diretorio_1)
print(new_file.absolute())  # Caminho absoluto do novo arquivo
new_file.touch(exist_ok=True)  # Cria o arquivo, se não existir


### Resolvendo caminhos relativos e absolutos
p = Path("..").absolute()    #/home/lusa/testes/..
print(p)

p = Path("..").resolve()     #/home/lusa (resolve os links simbólicos, se houver)
print(p)  

p = Path(__file__).resolve() #__file__ é uma variável especial que contém o caminho do arquivo atual
print(p)  

p = Path.home()              #Caminho do diretório home do usuário
print(p)  


### Glob patterns
for p in Path().glob("*.py"):  # Todos os arquivos .py no diretório atual
    print(p)

for p in Path().rglob("*.py"): # Todos os arquivos .py no diretório atual e subdiretórios
    print(p)


### Reading and writing files
arquivo = Path.home() / "testes/teste_arg.py"
    #print(arquivo) -> /home/lusa/teste_arg.py

with arquivo.open() as file:
    print(file.read())
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
