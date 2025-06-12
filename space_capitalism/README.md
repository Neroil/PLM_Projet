# PLM_Projet

## Démarrer avec docker

Pour lancer notre application sans installer Elixir localement, il est possible de la démarrer avec Docker. Pour cela, il suffit de cloner le repo et de démarre docker compose:
```bash
git clone https://github.com/Neroil/PLM_Projet.git
cd .\\PLM_Projet\\space_capitalism\\
docker compose up
```

## Démarre avec Elixir

### Prérequis

- Elixir (version 1.14 ou supérieure) ([installer](https://elixir-lang.org/install.html))
- Phoenix Framework ([installer](https://hexdocs.pm/phoenix/installation.html))

### Installation

1. Clonez le repository
```bash
git clone https://github.com/Neroil/PLM_Projet.git
```
2. Naviguez vers le dossier `space_capitalism`
```bash
cd .\\PLM_Projet\\space_capitalism\\
```
3. Installez et compilez les dépendances :
```bash
mix deps.get
mix deps.compile
```
4. Lancez le serveur :
```bash
mix phx.server
```

## Atteindre le site
Une fois démarrée, l'application sera accessible sur [http://localhost:4000](http://localhost:4000)