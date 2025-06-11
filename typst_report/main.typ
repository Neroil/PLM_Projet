#import "@preview/bubble:0.2.2": *

//Rules override
#show outline.entry.where(level: 1): it => {
  set text(size: 1.1em, weight: "bold")
  set block(above: 1.2em, below: 0.8em)
  it
}

#show outline.entry.where(level: 2): it => {
  set text(size: 0.9em)
  it
}

#show outline.entry.where(level: 3): it => {
  set text(size: 0.8em)
  it
}

#show raw.where(block: true): it => {
  set text(size: 0.8em)
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

// Reset page counter for outline pages (use roman numerals or no numbering)
#set page(numbering: "i")
#counter(page).update(1)

#outline(
  title: text(size: 1.3em, weight: "bold", fill: rgb("#A63A8F"))[Table des matières],
  indent: auto,
  depth: 3
)

#pagebreak()

// Start main content with page numbering from 1
#set page(numbering: "1")
#counter(page).update(1)

//#include "intermediary_report.typ"
#include "final_report.typ"