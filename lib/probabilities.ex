defmodule Survivor.Probabilities do
  defstruct [:date, :week, :team, :win_probability, :is_completed]

  def by_week(probs) do
    Enum.group_by(probs, fn team_game -> team_game.week end)
    |> Enum.filter(fn {key, _list} -> not is_nil(key) end)
    |> Enum.into(%{})
  end

  def filter_by_threshold(probs, threshold) do
    Enum.filter(probs, fn team_game -> team_game.win_probability >= threshold end)
  end

  defp download_file() do
    {:ok, resp} =
      :httpc.request(
        :get,
        {'https://projects.fivethirtyeight.com/nfl-api/nfl_elo_latest.csv', []},
        [],
        body_format: :binary
      )

    {{_, 200, 'OK'}, _headers, body} = resp

    File.write!("./temp/probabilities.csv", body)
  end

  def raw_probabilities() do
    download_file()

    csv =
      "../temp/probabilities.csv"
      |> Path.expand(__DIR__)
      |> File.stream!()
      |> CSV.decode!()

    headers = Enum.take(csv, 1) |> Enum.at(0)

    file = Enum.drop(csv, 1)

    # mapped =
    Enum.map(file, fn row ->
      row = 0..(length(row) - 1) |> Enum.zip(row)

      Enum.map(row, fn {index, val} ->
        {String.to_atom(Enum.at(headers, index)), val}
      end)
      |> Enum.into(%{})
    end)
  end

  def team_game_probabilities do
    raw_probabilities()
    |> Enum.reduce([], fn game, acc ->
      acc
      |> List.insert_at(
        -1,
        %Survivor.Probabilities{
          date: Date.from_iso8601!(game.date),
          team: game.team1,
          win_probability: String.to_float(game.qbelo_prob1),
          is_completed: "" != game.score1,
          week: get_week(Date.from_iso8601!(game.date))
        }
      )
      |> List.insert_at(
        -1,
        %Survivor.Probabilities{
          date: Date.from_iso8601!(game.date),
          team: game.team2,
          win_probability: String.to_float(game.qbelo_prob2),
          is_completed: "" != game.score2,
          week: get_week(Date.from_iso8601!(game.date))
        }
      )
    end)
  end

  @weeks [
    %{week: 1, start: ~D[2022-09-07], end: ~D[2022-09-13]},
    %{week: 2, start: ~D[2022-09-14], end: ~D[2022-09-20]},
    %{week: 3, start: ~D[2022-09-21], end: ~D[2022-09-27]},
    %{week: 4, start: ~D[2022-09-28], end: ~D[2022-10-04]},
    %{week: 5, start: ~D[2022-10-05], end: ~D[2022-10-11]},
    %{week: 6, start: ~D[2022-10-12], end: ~D[2022-10-18]},
    %{week: 7, start: ~D[2022-10-19], end: ~D[2022-10-25]},
    %{week: 8, start: ~D[2022-10-26], end: ~D[2022-11-01]},
    %{week: 9, start: ~D[2022-11-02], end: ~D[2022-11-08]},
    %{week: 10, start: ~D[2022-11-09], end: ~D[2022-11-15]},
    %{week: 11, start: ~D[2022-11-16], end: ~D[2022-11-22]},
    %{week: 12, start: ~D[2022-11-23], end: ~D[2022-11-29]},
    %{week: 13, start: ~D[2022-11-30], end: ~D[2022-12-06]},
    %{week: 14, start: ~D[2022-12-07], end: ~D[2022-12-13]},
    %{week: 15, start: ~D[2022-12-14], end: ~D[2022-12-20]},
    %{week: 16, start: ~D[2022-12-21], end: ~D[2022-12-27]},
    %{week: 17, start: ~D[2022-12-28], end: ~D[2023-01-03]},
    %{week: 18, start: ~D[2023-01-04], end: ~D[2023-01-10]}
  ]

  def get_week(date) do
    found =
      Enum.find(@weeks, fn week ->
        start_compare = Date.compare(week.start, date)
        end_compare = Date.compare(week.end, date)

        case {start_compare, end_compare} do
          {:eq, _} -> true
          {_, :eq} -> true
          {:lt, :gt} -> true
          _ -> false
        end
      end)

    if found do
      Map.get(found, :week)
    end
  end
end
