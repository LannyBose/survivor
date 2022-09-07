# Survivor

This code pulls 538's ELO rankings and walks the tree of possible picks to give you the best chance of finishing a Fantasy Football Survivor league.

In case you're not Elixir-y, here's some install instructions, assuming you're using ASDF as your package manager

```
asdf plugin add elixir
asdf plugin add erlang

asdf install elixir 13.3.3
asdf install erlang ___

mix deps.get
```

To open Elixir's REPL...

```
iex -S mix
```
To run the projections from the REPL:

```
Survivor.project()

```
Note that that's the _verb_ "project" as in "project the future" as opposed to the _noun_ project.

If you want to re-project the season after making picks, either pass in picks as a param, such as...

```
Survivor.project(
  week: 2, // This is the week you want to project _from_...
  picks: [

  ]
)
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `survivor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:survivor, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/survivor](https://hexdocs.pm/survivor).

