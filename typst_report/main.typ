#import "@preview/bubble:0.2.2": *

//Rules override
#show outline.entry.where(level: 1): it => {
  set text(size: 1.3em, weight: "bold")
  set block(above: 1.2em, below: 0.8em)
  it
}

#show outline.entry.where(level: 2): it => {
  set text(size: 1.1em)
  it
}

#show outline.entry.where(level: 3): it => {
  set text(size: 0.9em)
  it
}

#show selector(heading.where(level: 2)) : set heading(numbering: none)

//Theme instantiation
#show: bubble.with(
  title: "Paradigme de concurrence",
  subtitle: "En utilisant Elixir",
  author: "Guillaume Dunant & Edwin Häffner",
  affiliation: "HEIG-VD",
  date: datetime.today().display(),
  year: "2025",
  class: "ICSL",
  main-color: "A63A8F", //set the main color
  logo: image("media/logo.png"), //set the logo
) 

#outline(
  title: text(size: 1.3em, weight: "bold", fill: rgb("#A63A8F"))[Table des matières],
  indent: auto,
  depth: 3
)

#pagebreak()

= Introduction

L'idée derrière le paradigme de concurrence est de pouvoir efficacement gérer plusieurs tâches en parallèle sur une même machine, ou même sur plusieurs. L'objectif final est d'optimiser l'utilisation des ressources disponibles, de réduire les temps d'attente et d'accélérer l'exécution des programmes en répartissant les calculs ou les opérations entre plusieurs processus ou threads qui s'exécutent simultanément. 

Un exemple simple serait d'avoir une application qui utilise un thread du CPU pour afficher la partie GUI (interface graphique) et un autre thread pour effectuer des calculs en arrière-plan. Cela éviterait de bloquer l'affichage graphique lorsqu'un calcul complexe est demandé, améliorant ainsi la fluidité et la réactivité de l'application.

= Motivations du choix de la concurrence

La concurrence est devenue essentielle dans le développement de logiciels modernes. Les CPU actuels disposent d'un nombre croissant de cœurs, même dans le marché des processeurs abordables, par exemple, un processeur à moins de 100 francs offre déjà au moins 6 cœurs.

Donc il nous faut pouvoir utiliser ces cœurs maintenant si abondant pour pouvoir faire des applications efficace.

La concurrence est aussi très importante lorsqu'on interagit avec des API web et d'autres machines. La communication n'est pour l'instant pas instantanée et il faut alors avoir un mécanisme d'attente qui ne fait pas arrêter le programme. Les opérations d'entrée/sortie (I/O), comme les requêtes réseau ou les accès disque, sont particulièrement concernées car elles comportent des temps d'attente réel.

= Paradigme de concurrence

La programmation concurrente est donc une façon de programmer en tenant compte de l'existence de ces threads et processus. Elle implique la conception de programmes où plusieurs séquences d'instructions peuvent s'exécuter simultanément ou en alternance rapide (préemption de plusieurs processus entre eux par exemple).

Ce paradigme introduit des concepts spécifiques comme la synchronisation, les verrous, les sémaphores, les variables atomiques, et les files de messages, qui permettent de coordonner l'exécution des différents processus ou threads et d'éviter les problèmes classiques de concurrence comme les race conditions, les deadlocks ou les famines.

= Pourquoi Elixir est la solution ?

Elixir tourne sur la machine virtuelle d'Erlang qui est nommée BEAM. Plus précisemment le code Elixir est compilé dans un bytecode qui tourne sur BEAM. 

== Qu'est ce que c'est BEAM ?

BEAM, qui veut dire en français "La machine abstraite Erlang de Bogdan" est la machine virtuelle qui exécute le bytecode compilé des programmes Erlang et Elixir. 

Vu que cette machine virtuelle a été développé pour l'ecosytème Erlang/OTP (Open Telecom Platform), elle est spécialement conçue pour répondre aux exigences liées à la télécommunication, la haute disponibilité, la tolérance aux pannes et la concurrence. 

*Voici ses caractéristiques :*

=== Gestion de la concurrence
BEAM exécute des processus légers qui ne partagent pas de mémoire. Ces processus communiquent uniquement via un passage de *messages asynchrone*, ce qui permet d'éviter les problèmes courants liés aux accès concurrents comme les conditions de course et les verrous. Cette isolation entre les processus est la base de la tolérance aux pannes : si l'un des processus échoue, il n'impactera pas les autres.

=== Planificateurs multicœurs efficaces
Initialement, BEAM utilisait une seule file d'attente d'exécution (run queue). Aujourd'hui, elle attribue une file d'attente à chaque cœur de processeur disponible, ce qui permet de paralléliser les programmes de manière optimale dynamiquement selon le nombre de cœurs de la machine.
#figure(
  image("media/1-Erlang-Virtual-Machine-the-BEAM-Google-Docs-1024x775.png", width: 60%),
  caption: [
    Files d'executions sur chaque cœurs.
  ],
)

=== Tolérance aux pannes grâce à la gestion des erreurs
Contrairement à un language comme Java ou l'erreur est fatale, Erlang prone la philosophie du "let it crash". Comme dit précédemment, cela signifie que les processus sont conçus pour échouer de manière isolée et sans impact sur le reste du système. Lorsqu'un processus rencontre une erreur, il peut simplement se planter sans essayer de corriger l'exception, tandis qu'un autre processus, souvent supervisé par un superviseur OTP, prendra en charge sa relance.

=== Collecte de déchets par processus
BEAM utilise une gestion automatisée de la mémoire avec un système de garbage collection par processus, ce qui permet de maintenir des temps de réponse constants (de l'ordre de la milliseconde), sans impact négatif sur la performance globale.


== Paradigme fonctionnel
Outre le paradigme de concurrence, il nous semblait important de pour une fois effectuer un projet en entier en utilisant un language fonctionnel. Dans le cadre de notre cours de "Paradigme et Language de Programmation", on a pu se mouiller les mains avec Haskell, mais outre les mini programmes que nous avions pu réaliser, nous n'avions jamais fait de "grand" projet du début à la fin en utilisant un language fonctionnel.

Dans la programmation fonctionnelle, une variable est toujours immuable, il n'y a pas de système de reassignments de valeurs, donc les problèmes liés à la synchronisation disparaissent. 

== Processus légers

En parlant de BEAM, on a pu parler de l'utilisation de processus légers, mais que sont-ils ? 




= La concurrence dans Elixir

== Les outils de base
=== Les processus
En elixir, il est assez simple de créer un nouveau processus. Pour cela, il faut appeler la méthode `spawn` qui prend en paramètre un fonction à exécuter et qui retourne son pid (Processus ID).

```ex
pid = spawn(fn -> 1 + 2 end)
```

Cela crée un processus indépendant, c'est à dire que si celui-ci crash, le processus l'ayant créé (son parent) continuera sans s'en soucier. Il est donc également aussi de créer un processus lié à un autre un appelant la méthode `spawn_link`. Cela aura pour conséquence que si un processus crash, le signal de terminaison sera transmis à son parent.

=== Les messages
Afin de pouvoir communiquer entre les processus, il est possible d'envoyer et de recevoir des messages. La méthode `send(dest, msg)` permet d'envoyer un message, où `dest` est la destination du message (celui-ci peut être un pid local ou distant, un port local, ou autre ...) et `msg` le contenu du message. Cette méthode est non bloquante. Le message est ajouté à la "boîte aux lettres" (mailbox) du processus. Ces messages peuvent être récupérés via la construction `receive`. Celle-ci permet de récupéré un message selon un pattern ou d'attendre qu'un message arrive.

```ex
pid = spawn(fn -> 
  receive do
    {:hello, msg} -> msg
    {:world, _msg} -> "Not a match"
  after
    1_000 -> "Timeout"
  end
end)

send(pid, {:hello, "World"})
```

Comme `receive` est bloquant, il est possible de définir un timeout grâce au mot-clé `after`.

== Open Telecom Platform (OTP) 
OTP est un ensemble d'outils permettant de simplifier la création de système distribué. A l'origine développé pour le langage Erlang, les bibliothèques d'OTP sont également disponible en Elixir.

== GenServer
Les GenServer (Generic Server) sont une abstraction qui permettent à un processus de pouvoir gérer un état interne et à des processus externe de communiquer avec lui via des messages synchrones ou asynchrones. Les messages sysnchrones signifient que l'envoyeur attend la réponse alors les messages asynchrones n'attendent pas de réponse. Cette abstraction va implémenter toutes la logique de l'écoute de message et de gestion de l'état, laissant au développeur la seul résponsabilité d'implémenter les callbacks nécessaire. Voici un exemple de GenServer implémentant une stack:

#figure(caption: [Exemple de GenServer #footnote[https://hexdocs.pm/elixir/GenServer.html]],
```ex
defmodule Stack do
  use GenServer

  # Callbacks

  @impl true
  def init(elements) do
    initial_state = String.split(elements, ",", trim: true)
    {:ok, initial_state}
  end

  @impl true
  def handle_call(:pop, _from, state) do
    [to_caller | new_state] = state
    {:reply, to_caller, new_state}
  end

  @impl true
  def handle_cast({:push, element}, state) do
    new_state = [element | state]
    {:noreply, new_state}
  end
end
```
)

On peut voir dans l'exemple les trois principaux callbacks:
- `init(init_args)` : Permet de définir le comportement du GenServer lors du démarrage du serveur.
- `handle_call(request, from, state)` : Permet de gérer un appel synchrone. Il est possible d'en définir plusieurs pour des `request` différentes. `state` correspond à l'état interne maintenu par le serveur. La valeur retournée à l'appelant est la valeur de `to_caller` et le nouvelle état qui sera transmis au prochain callback est `new_state`.
- `handle_cast(request, state)` : Comme `handle_call` mais pour les appels asynchrones. La principal différence est que le résultat est un `:noreply`, c'est-à-dire qu'aucune valeur n'est retournée à l'appelant.

Il 

= Cahier des charges prévisionnel

= Recherches effectuées 

Cette rubrique est pour l'instant temporaire, mais nous permet de nous mettre à jour sur ce que nous avons fait lors des jours. A refactor plus tard de façon plus propre 

== 13-03-25

Recherche sur l'initialisation de projets phoenix, notamment en utilisant cette ressource ci : https://hexdocs.pm/phoenix/up_and_running.html

De plus, on a pu trouver un site qui permet de faire des exercices liés à Elixir ici un lien sur la section de la concurrence : https://elixirschool.com/en/lessons/advanced/otp_concurrency

== 27-03-25

Début du rapport intermédiaire ! 

= Bibliographie

https://www.erlang-solutions.com/blog/comparing-elixir-vs-java/

https://medium.com/flatiron-labs/elixir-and-the-beam-how-concurrency-really-works-3cc151cddd61

https://medium.com/@ck3g/introduction-to-otp-genservers-and-supervisors-cf1358d545

https://hexdocs.pm/elixir/processes.html

https://elixirschool.com/en/lessons/advanced/otp_concurrency

== BEAM 
https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)

https://www.erlang.org/blog/a-brief-beam-primer/

https://www.erlang.org/blog/beam-compiler-history/

https://www.erlang-solutions.com/blog/the-beam-erlangs-virtual-machine/

https://elixirschool.com/en/lessons/advanced/otp_supervisors

= Feature

== Customized items


Figures are customized but this is settable in the template file. You can of course reference them  : @ref.

#figure(caption: [Code example],
```rust
fn main() {
  println!("Hello Typst!");
}
```
)<ref>
