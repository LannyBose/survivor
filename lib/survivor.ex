defmodule Survivor do
  @moduledoc """
  Documentation for `Survivor`.
  """

  @picks [
    %Survivor.Probabilities{
      is_completed: true,
      team: "LAR",
      week: 1,
      win_probability: 1
    },
    %Survivor.Probabilities{
      is_completed: true,
      team: "CLE",
      week: 2,
      win_probability: 1
    },
    %Survivor.Probabilities{
      is_completed: true,
      team: "DEN",
      week: 3,
      win_probability: 1
    },
    %Survivor.Probabilities{
      is_completed: true,
      team: "BUF",
      week: 4,
      win_probability: 1
    },
    %Survivor.Probabilities{
      is_completed: true,
      team: "MIN",
      week: 5,
      win_probability: 1
    }
  ]

  @week 6
  @threshold 0.72

  def project(opts \\ []) do
    threshold = opts[:threshold] || @threshold
    week = opts[:week] || @week
    picks = opts[:picks] || @picks

    {microseconds, results} =
      :timer.tc(fn ->
        Survivor.Picks.stream(week, picks, threshold)
      end)

    IO.puts("Completed projections in #{microseconds / 1_000_000} seconds")

    results
  end
end
