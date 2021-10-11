defmodule SurvivorTest do
  use ExUnit.Case
  doctest Survivor

  test "greets the world" do
    assert Survivor.hello() == :world
  end
end
