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

= Présentation de BEAM

Elixir tourne sur la machine virtuelle d'Erlang qui est nommée BEAM. Plus précisément le code Elixir est compilé dans un bytecode qui tourne sur BEAM. Il faut alors présenter ce que c'est BEAM avant de se focaliser sur Elixir.

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
Contrairement à un language comme Java ou l'erreur est fatale si non traitée dans un bloc try catch, Erlang prone la philosophie du "let it crash". Comme dit précédemment, cela signifie que les processus sont conçus pour échouer de manière isolée et sans impact sur le reste du système. Lorsqu'un processus rencontre une erreur, il peut simplement se planter sans essayer de corriger l'exception, tandis qu'un autre processus, souvent supervisé par un superviseur OTP, prendra en charge sa relance. Nous reparlerons de ce superviseur lorsque nous parlerons d'Elixir !

=== Collecte de déchets par processus

Chaque processus dans BEAM possède son propre tas et sa propre pile, alloués dans un même bloc mémoire et croissant l'un vers l'autre. Lorsque la pile et le tas se rencontrent, le collecteur de déchets (garbage collector) est déclenché pour récupérer la mémoire inutilisée. Si la mémoire récupérée s'avère insuffisante, la taille du tas est augmentée pour répondre aux besoins croissants du processus.

Cette approche, où chaque processus dispose de son propre collecteur de déchets, présente plusieurs avantages. Tout d'abord, elle permet d'isoler les pauses dues à la collecte de déchets à un seul processus, sans affecter les autres. Cela réduit considérablement les interruptions globales du système, améliorant ainsi la réactivité et la fluidité des applications.

De plus, les pauses induites par la collecte de déchets sont généralement très courtes, car elles se limitent à la mémoire utilisée par un seul processus.

Cependant, il faut faire attention aux problèmes de duplication des informations entre les processus vu que la mémoire n'est pas partagée.

= Pourquoi Elixir est la solution ?

== Paradigme fonctionnel
Outre le paradigme de concurrence, il nous semblait important de pour une fois effectuer un projet en entier en utilisant un language fonctionnel. Dans le cadre de notre cours de "Paradigme et Language de Programmation", on a pu se mouiller les mains avec Haskell, mais outre les mini programmes que nous avions pu réaliser, nous n'avions jamais fait de "grand" projet du début à la fin en utilisant un language fonctionnel.

Dans la programmation fonctionnelle, une variable est toujours immuable, il n'y a pas de système de reassignments de valeurs, donc certains problèmes liés à la synchronisation disparaissent. Pas tous par contre, notamment lors des problèmes de coordinations entre différentes entités.

== Les processus légers

En évoquant BEAM, nous avons mentionné l'utilisation de processus légers, mais que sont-ils exactement ?

Les processus légers sont des entités gérées directement par la machine virtuelle, contrairement aux processus natifs ou aux processus virtuels mappés sur des threads réels du système d'exploitation. Dans le cas d'Elixir, ces processus ne sont pas liés à un thread OS, mais sont entièrement administrés par la VM BEAM.

Grâce à l'absence d'appels système lors de leur création, ces processus peuvent être générés en très grand nombre et de manière extrêmement rapide.

Cependant, cette gestion par BEAM n'est pas sans inconvénients. Pour des tâches purement computationnelles, comme des calculs complexes, la surcharge introduite par l'ordonnancement et la gestion des processus légers peut ralentir l'exécution par rapport à une approche utilisant des threads natifs optimisés pour le CPU.

De plus, bien que ces processus soient légers, ils ne sont pas gratuits en termes de mémoire. Chaque processus dispose de sa propre pile, ce qui nécessite une gestion attentive de l'espace mémoire disponible.

Malgré ces limitations, les processus légers restent l'une des principales forces d'Elixir, offrant une solution puissante et flexible pour la gestion de la concurrence.


= La concurrence dans Elixir

== Les outils de base
En Elixir, il est assez simple de créer un nouveau processus. 


= Cahier des charges prévisionnel

== Nom du projet : Space Capitalism 

== Description

Space Capitalism est un jeu de gestion d'un empire galactique jouable sur le web. Le joueur incarne un dirigeant interstellaire qui doit gérer ses ressources, coloniser des planètes, miner des astéroïdes et développer son économie pour prospérer dans un univers sans foi ni lois.

== Gameplay

Le joueur commence sa partie avec des ressources de bases, une planète, des travailleurs et quelque vaisseaux de minage. Le joueur peut améliorer sa troupe en améliorant de façon verticale ou horizontale pour pouvoir amasser le plus de ressources possible.

=== Utilisation des ressources

Les ressources collectées peuvent être utilisées de deux manières principales : 

+ *Investissement dans la bourse galactique* : Maximiser les profits en spéculant sur les fluctuations économiques interstellaires.
+ *Amélioration des infrastructures et des unités* : Acheter des éléments pour renforcer sa flotte, améliorer les capacités de production ou développer de nouvelles technologies.

=== Interactions et défis

Le joueur devra également faire face à des défis tels que la concurrence avec d'autres empires, des crises économiques, ou des événements aléatoires qui peuvent influencer en bien comme en mal le déroulement de la partie!


== But final du jeu 

Le but ultime est de prospérer le plus longtemps possible en évitant la faillite. Dès que l'argent rentre dans le négatif, c'est la fin !


== Utilisation de la concurrence dans le projet

Le but de ce jeu est de simuler cette gestion, chaque travailleur, vaisseau ou même planète sera son propre processus. La bourse elle même sera un procesus, donc le défi sera la communication entre ces centaines de processus de façon concurrente ! 

== Technologies utilisées

Le framework Phoenix, basé sur Elixir, sera utilisé pour développer le jeu. Ce choix garantit une gestion optimale de la concurrence et une scalabilité adaptée à un jeu en ligne.





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

https://medium.com/elemental-elixir/elixir-otp-basics-of-processes-d3437607d12b#:~:text=Elixir%20processes%20are%20similar%20to,internally%20by%20the%20Beam%20VM.

== BEAM 
https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)

https://www.erlang.org/blog/a-brief-beam-primer/

https://www.erlang.org/blog/beam-compiler-history/

https://www.erlang-solutions.com/blog/the-beam-erlangs-virtual-machine/

https://elixirschool.com/en/lessons/advanced/otp_supervisors

https://www.erlang.org/doc/apps/erts/garbagecollection.html



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
