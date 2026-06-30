## argparse
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

"""
Linha de comando e retornos
python teste_arg.py oi
oi
oi
python teste_arg.py oi -t 1
oi
"""

## Agora, adicionando flags opcionais com escolhas
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


"""
Linha de comando e retornos
python teste_arg.py rodrigo
Olá! rodrigo
python teste_arg.py rodrigo -l en
Hello! rodrigo
"""
