defmodule Survivor.Picks do
  alias Survivor.Picks
  alias Survivor.Probabilities
  defstruct [:picks, :probability, :expected_return]

  @win_probability_threshold 0.7
  @end_week 19

  def run(week \\ 1, picks \\ []) do
    probs_by_week =
      Probabilities.team_game_probabilities()
      |> Probabilities.filter_by_threshold(@win_probability_threshold)
      |> Probabilities.by_week()

    build_picks(week, probs_by_week, picks)
    |> List.flatten()
  end

  def build_picks(@end_week, _, picks) do
    probability = Enum.reduce(picks, 1, fn pick, acc -> acc * pick.win_probability end)

    %Picks{
      picks: picks,
      probability: probability,
      expected_return: 6562.33 * probability
    }
  end

  def build_picks(week, probabilities, previous_picks) do
    if is_nil(probabilities[week]) do
      short_circuit(previous_picks, week)
    else
      teams_available_this_week =
        Enum.filter(probabilities[week], fn team_this_week ->
          is_nil(Enum.find(previous_picks, fn pick -> pick.team == team_this_week.team end))
        end)

      if length(teams_available_this_week) == 0 do
        short_circuit(previous_picks, week)
      else
        Enum.map(teams_available_this_week, fn team ->
          build_picks(week + 1, probabilities, List.insert_at(previous_picks, -1, team))
        end)
      end
    end
  end

  defp short_circuit(previous_picks, week) do
    build_picks(@end_week, nil, List.insert_at(previous_picks, -1, short_circuit(week)))
  end

  defp short_circuit(week) do
    %Probabilities{
      week: week,
      team: "NO TEAM AVAILABLE",
      win_probability: 0,
      is_completed: false
    }
  end
end
