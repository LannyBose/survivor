defmodule Survivor do
  @moduledoc """
  Documentation for `Survivor`.
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
  @end_week 16

  # Benchmarking for week = 1, picks = [] (no logging until 0.69)
  #
  # Threshold    Func           Paths         Time      Memory Spike
  # 0.73         Enum         462_734         2.44
  # 0.73         Stream       462_734         2.83
  #
  # 0.72         Enum       1_277_073         8.08
  # 0.72         Stream     1_277_073         7.38
  #
  # 0.71         Enum       4_509_226        28.96
  # 0.71         Stream     4_509_226        21.01
  #
  # 0.70         Enum      12_433_220       108.62           9.99 GB
  # 0.70         Stream    12_433_220        66.84           0.23 GB
  #
  # 0.69         Enum      61_961_756      1482.70          66.43 GB
  # 0.69         Stream    61_961_756       594.15           0.23 GB

  # Benchmarking for week = 6 with picks (with logging)
  # Threshold    Func           Paths           Time
  # 0.74         Stream            82       0.243103
  # 0.73         Stream         1_092       0.505637
  # 0.72         Stream         2_978       0.488754
  # 0.71         Stream         6_565       0.238408
  # 0.70         Stream        13_959       0.306899
  # 0.69         Stream        20_896       0.349672
  # 0.68         Stream        25_972       0.395589
  # 0.67         Stream        62_262       0.678287
  # 0.66         Stream       308_699       2.701326
  # 0.65         Stream       354_966       3.120775
  # 0.64         Stream       354_966       3.160029
  # 0.63         Stream       871_036       7.353442
  # 0.62         Stream     9_408_908      64.533385
  # 0.61         Stream    19_332_418     133.362729
  # 0.60         Stream    33_967_151     237.914030

  @threshold 0.63

  def project_streaming(
        threshold \\ @threshold,
        week \\ @week,
        picks \\ @picks_so_far
      ) do
    {microseconds, {count, results}} =
      :timer.tc(fn ->
        Survivor.Picks.stream(week, picks, threshold)
        |> Enum.reduce({0, nil}, fn picks, {count, max} ->
          if is_nil(max) || max.probability < picks.probability do
            {count + 1, picks}
          else
            {count + 1, max}
          end
        end)
      end)

    IO.puts(
      "Completed projections in #{microseconds / 1_000_000} seconds, evaluating #{count} paths."
    )

    results
  end

  def project(week \\ @week, picks \\ @picks_so_far, threshold \\ @threshold) do
    {microseconds, {count, results}} =
      :timer.tc(fn ->
        Survivor.Picks.run(week, picks, threshold)
        |> Enum.reduce({0, nil}, fn picks, {count, max} ->
          if is_nil(max) || max.probability < picks.probability do
            {count + 1, picks}
          else
            {count + 1, max}
          end
        end)
      end)

    IO.puts(
      "Completed projections in #{microseconds / 1_000_000} seconds, evaluating #{count} paths."
    )

    results
  end

  def stream(opts \\ []) do
    threshold = opts[:threshold] || @threshold
    week = opts[:week] || @week

    picks = opts[:picks] || @picks_so_far

    end_week = opts[:end_week] || @end_week
    get_file()

    probs_by_week =
      file_to_probabilities()
      |> to_probabilities_above_threshold(threshold)
      |> without_existing_picks(picks)
      |> to_by_week(week, end_week)

    make_picks(week, probs_by_week, picks, end_week)
  end

  defp get_file() do
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

  # Date is at position 0
  # Team 1 is at position 4
  # Team 2 is at position 5
  # Team 1 QB elo is at position 20
  # Team 2 QB elo is at position 21
  # Game score 1 is at position 29
  # Game score 2 is at position 30

  defp file_to_probabilities() do
    "../temp/probabilities.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode!()
    # Remove headers
    |> Stream.drop(1)
    |> Stream.flat_map(fn row ->
      date = Date.from_iso8601!(Enum.at(row, 0))

      [
        %Survivor.Probabilities{
          date: date,
          team: Enum.at(row, 4),
          win_probability: String.to_float(Enum.at(row, 20)),
          is_completed: "" != Enum.at(row, 28),
          week: Survivor.Probabilities.get_week(date)
        },
        %Survivor.Probabilities{
          date: date,
          team: Enum.at(row, 5),
          win_probability: String.to_float(Enum.at(row, 21)),
          is_completed: "" != Enum.at(row, 29),
          week: Survivor.Probabilities.get_week(date)
        }
      ]
    end)
  end

  defp to_probabilities_above_threshold(stream, threshold) do
    Stream.filter(stream, fn probability ->
      probability.win_probability >= threshold
    end)
  end

  defp without_existing_picks(stream, picks) do
    picks = Enum.map(picks, fn pick -> pick.team end)

    Stream.reject(stream, fn probability ->
      probability.team in picks
    end)
  end

  defp to_by_week(stream, week, end_week) do
    week..end_week
    |> Stream.map(fn week_number ->
      {week_number, Enum.filter(stream, fn probability -> probability.week == week_number end)}
    end)
    |> Enum.into(%{})
  end

  # def make_picks(
  #       week,
  #       probs_by_week,
  #       initial_picks,
  #       end_week,
  #       picks \\ [],
  #       working_probability \\ 1
  #     ) do
  #   case initial_picks[week] do
  #     nil ->
  #       Stream.reject(probs_by_week[week], fn team_this_week ->
  #         team_this_week in team_list(picks)
  #       end)
  #       |> Stream.transform(0, fn team_this_week, best_prob ->
  #         current_prob = working_probability * team_this_week.win_probability

  #         if current_prob < best_prob do
  #           {[nil], best_prob}
  #         else
  #           new_picks = [team_this_week | picks]

  #           if week == end_week do
  #             {
  #               [
  #                 %Survivor.Picks{
  #                   picks: new_picks,
  #                   probability: current_prob,
  #                   expected_return: 6562.33 * current_prob
  #                 }
  #               ],
  #               current_prob
  #             }
  #           else
  #             case make_picks(
  #                    week + 1,
  #                    probs_by_week,
  #                    initial_picks,
  #                    end_week,
  #                    new_picks,
  #                    working_probability * team_this_week.win_probability
  #                  ) do
  #               nil -> {[nil], best_prob}
  #               new_best -> {[new_best], new_best.win_probability}
  #             end
  #           end
  #         end
  #       end)
  #       |> Enum.at(-1)

  #     pick ->
  #       make_picks(
  #         week + 1,
  #         probs_by_week,
  #         initial_picks,
  #         end_week,
  #         [pick | picks],
  #         working_probability * pick.win_probability
  #       )
  #   end
  # end

  def make_picks(week, probs, picks, end_week, working_prob \\ 1)

  def make_picks(week, _probs, picks, end_week, working_prob)
      when week > end_week do
    %Survivor.Picks{
      picks: picks,
      probability: working_prob,
      expected_return: 6562.33 * working_prob
    }
  end

  def make_picks(week, probs, picks, end_week, working_prob) do
    empty_pickset = %Survivor.Picks{picks: [], probability: 0, expected_return: 0}

    Stream.reject(probs[week] || [], fn team_this_week ->
      team_this_week.team in team_list(picks)
    end)
    |> Enum.reduce(empty_pickset, fn team, best ->
      IO.puts("Week #{week}: #{team.team}")
      current_probability = working_prob * team.win_probability

      if current_probability < best.probability do
        best
      else
        result =
          make_picks(
            week + 1,
            probs,
            [team | picks],
            end_week,
            current_probability
          )

        if result.probability > best.probability do
          result
        else
          best
        end
      end
    end)

    # |> Stream.flat_map(fn team ->
    #   make_picks(
    #     week + 1,
    #     probs,
    #     [team | picks],
    #     end_week,
    #     cutoff_prob,
    #     working_prob * team.win_probability
    #   )
    # end)
  end

  defp team_list(picks) do
    Enum.map(picks, fn pick -> pick.team end)
  end
end
