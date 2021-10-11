defmodule Survivor do
  @moduledoc """
  Documentation for `Survivor`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Survivor.hello()
      :world

  """

  @picks_so_far [
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

  def project(week \\ @week, picks \\ @picks_so_far) do
    {microseconds, results} =
      :timer.tc(fn ->
        Survivor.Picks.run(week, picks)
        |> Enum.sort_by(fn picks -> picks.probability end, :desc)
      end)

    seconds = microseconds / 1_000_000
    IO.puts("Completed projections in #{seconds} seconds, evaluating #{length(results)} paths.")
    Enum.at(results, 0)
  end
end
