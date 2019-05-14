defmodule CodeRunnerTest do
  use ExUnit.Case
  doctest CodeRunner

  test "greets the world" do
    assert CodeRunner.hello() == :world
  end
end
