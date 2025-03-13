#import "@preview/bubble:0.2.2": *

#show: bubble.with(
  title: "Paradigme de concurrence",
  subtitle: "En utilisant Elixir",
  author: "Guillaume Dunant & Edwin Häffner",
  affiliation: "HEIG-VD",
  date: datetime.today().display(),
  year: "2025",
  class: "ICSL",
  //main-color: "4DA6FF", //set the main color
  logo: image("logo.png"), //set the logo
) 

// Edit this content to your liking

= Introduction

This is a simple template that can be used for a report.

= Recherches effectuées 

Cette rubrique est pour l'instant temporaire, mais nous permet de nous mettre à jour sur ce que nous avons fait lors des jours. A refactor plus tard de façon plus propre 

== 13-03-25

Recherche sur l'initalisation de projets phoenix, notamment en utilisant cettre ressource ci : https://hexdocs.pm/phoenix/up_and_running.html

Deplus on a pu trouver un site qui permet de faire des exercices liés à Elixir ici un lien sur la section de la concurrence : https://elixirschool.com/en/lessons/advanced/otp_concurrency

= Features
== Colorful items

The main color can be set with the `main-color` property, which affects inline code, lists, links and important items. For example, the words highlight and important are highlighted !

- These bullet
- points
- are colored

+ It also
+ works with
+ numbered lists!

== Customized items


Figures are customized but this is settable in the template file. You can of course reference them  : @ref.

#figure(caption: [Code example],
```rust
fn main() {
  println!("Hello Typst!");
}
```
)<ref>

#pagebreak()

= Enjoy !

#lorem(100)