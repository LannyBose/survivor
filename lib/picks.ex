defmodule Survivor.Picks do
  alias Survivor.Picks
  alias Survivor.Probabilities
  defstruct [:picks, :probability, :expected_return]

  @win_probability_threshold 0.7

  def run(week \\ 1, picks \\ []) do
    probs_by_week =
      Probabilities.team_game_probabilities()
      |> Probabilities.filter_by_threshold(@win_probability_threshold)
      |> Probabilities.by_week()

    build_picks(week, probs_by_week, picks)
    |> List.flatten()
  end

  def build_picks(17, _, picks) do
    probability = Enum.reduce(picks, 1, fn pick, acc -> acc * pick.win_probability end)

    %Picks{
      picks: picks,
      probability: probability,
      expected_return: 6562.33 * probability
    }
  end

  def build_picks(week, probabilities, previous_picks) do
    teams_available_this_week =
      Enum.filter(probabilities[week], fn team_this_week ->
        is_nil(Enum.find(previous_picks, fn pick -> pick.team == team_this_week.team end))
      end)

    Enum.map(teams_available_this_week, fn team ->
      build_picks(week + 1, probabilities, List.insert_at(previous_picks, -1, team))
    end)
  end
end
