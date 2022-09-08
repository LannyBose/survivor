# Survivor

This code pulls 538's ELO rankings and walks the tree of possible picks to give you the best chance of finishing a Fantasy Football Survivor league.

In case you're not Elixir-y, here's some install instructions, assuming you're using ASDF as your language version manager:

```
asdf plugin add elixir
asdf plugin add erlang

asdf install elixir 13.3.3
asdf install erlang 24.3

mix deps.get
```

To open Elixir's REPL...

```
iex -S mix
```
To run the projections from the REPL:

```
Survivor.project(threshold: 0.68)

```
Note that that's the _verb_ "project" as in "project the future" as opposed to the _noun_ project.

In subsequent weeks, pass in your picks as an array of maps. You've gotta pass week and team.

```
Survivor.project(
  week: 2,
  picks: [
    %{week: 1, team: "LAR"}
  ],
  threshold: 0.68
)
```

## Time to compute

Benchmarking in 2022 start-of-season on an M1 Mac

Threshold     Time to compute
.68              25.197168 seconds
.675             67.476598 seconds
.66             179.572148 seconds
.65             822.733092 seconds
.64            4252.973664 seconds

...all resulting in the same picks on 2022-09-07.