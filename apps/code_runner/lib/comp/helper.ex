defmodule CodeRunner.Comp.Helper do
  def append(map, type, column \\ 0) do
    map
    |> Map.put("type", type)
    |> Map.put("column", column)
  end

  def parse_clike(msg, pattern) do
    parse_(~r/(?<file>.+)\:(?<row>\d+)\:[^\:]+\:.*\: (?<text>.*)/, msg, pattern)
    |> decrease_row_by1
  end

  def parse_(regex, msg, pattern) do
    Regex.scan(~r/.*#{pattern}.*/, msg)
    |> List.flatten()
    |> Enum.map(&Regex.named_captures(regex, &1))
    |> Enum.filter(&(not is_nil(&1)))
  end

  def decrease_row_by1(details) do
    Enum.map(details, &minus1(&1))
  end

  defp minus1(detail) do
    Map.update(detail, "row", 1, &to_string(String.to_integer(&1) - 1))
  end
end
