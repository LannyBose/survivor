defmodule Survivor.Picks do
  alias Survivor.Picks
  alias Survivor.Probabilities
  defstruct [:picks, :probability, :expected_return]

  @end_week 17

  def stream(week, picks, threshold) do
    probs_by_week =
      Probabilities.team_game_probabilities()
      |> Probabilities.filter_by_threshold(threshold)
      |> Probabilities.by_week()

    stream_picks(week, probs_by_week, picks)
  end

  def stream_picks(@end_week, _, picks) do
    probability = Enum.reduce(picks, 1, fn pick, acc -> acc * pick.win_probability end)
    # IO.puts("Pickset #{System.unique_integer(~w[monotonic positive]a)}")

    [
      %Picks{
        picks: picks,
        probability: probability,
        expected_return: 6562.33 * probability
      }
    ]
  end

  def stream_picks(week, probabilities, previous_picks) do
    Stream.filter(probabilities[week] || [], fn team_this_week ->
      is_nil(Enum.find(previous_picks, fn pick -> pick.team == team_this_week.team end))
    end)
    |> Stream.flat_map(fn team ->
      stream_picks(week + 1, probabilities, List.insert_at(previous_picks, -1, team))
    end)
  end

  def run(week, picks, threshold) do
    probs_by_week =
      Probabilities.team_game_probabilities()
      |> Probabilities.filter_by_threshold(threshold)
      |> Probabilities.by_week()

    build_picks(week, probs_by_week, picks)
    |> List.flatten()
  end

  def build_picks(@end_week, _, picks) do
    probability = Enum.reduce(picks, 1, fn pick, acc -> acc * pick.win_probability end)
    # IO.puts("Pickset #{System.unique_integer(~w[monotonic positive]a)}")

    [
      %Picks{
        picks: picks,
        probability: probability,
        expected_return: 6562.33 * probability
      }
    ]
  end

  def build_picks(week, probabilities, previous_picks) do
    Enum.filter(probabilities[week] || [], fn team_this_week ->
      is_nil(Enum.find(previous_picks, fn pick -> pick.team == team_this_week.team end))
    end)
    |> Enum.flat_map(fn team ->
      build_picks(week + 1, probabilities, List.insert_at(previous_picks, -1, team))
    end)
  end
end
