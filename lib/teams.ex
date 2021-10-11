defmodule Survivor.Teams do
  @teams ~w(TB LAC ARI BAL GB DAL KC NO TEN SEA SF IND CIN NE CAR OAK CHI WSH PHI PIT ATL MIA NYG HOU NYJ JAX DET LAR CLE DEN BUF MIN)

  def all() do
    @teams
  end

  def available(picked) do
    all()
    |> Enum.filter(fn team -> not Enum.member?(picked, team) end)
  end
end
