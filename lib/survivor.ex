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

  @win_probability_threshold 0.72

  def project_streaming(
        threshold \\ @win_probability_threshold,
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

  def project(week \\ @week, picks \\ @picks_so_far, threshold \\ @win_probability_threshold) do
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
end
