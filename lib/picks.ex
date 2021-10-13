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

    stream_picks(week, probs_by_week, picks, 1)
  end

  def stream_picks(@end_week, _, picks, prob_so_far) do
    # IO.puts("Pickset #{System.unique_integer(~w[monotonic positive]a)}")

    [
      %Picks{
        picks: picks,
        probability: prob_so_far,
        expected_return: 6562.33 * prob_so_far
      }
    ]
  end

  def stream_picks(week, probabilities, previous_picks, prob_so_far) do
    Stream.filter(probabilities[week] || [], fn team_this_week ->
      is_nil(Enum.find(previous_picks, fn pick -> pick.team == team_this_week.team end))
    end)
    |> Stream.flat_map(fn team ->
      current_prob = team.win_probability * prob_so_far

      stream_picks(
        week + 1,
        probabilities,
        List.insert_at(previous_picks, -1, team),
        current_prob
      )
    end)
  end
end
