defmodule CodeRunner.Project do
  require File

  def init!(folder, base),
    do: path(folder, base) |> init!

  def init!(folder) do
    if not exists?(folder) do
      File.mkdir_p!(folder)
    end
  end

  def delete(folder, base),
    do: path(folder, base) |> delete

  def delete(folder) do
    File.rm_rf!(folder)
  end

  def exists?(folder, base),
    do: path(folder, base) |> exists?

  def exists?(folder) do
    File.exists?(folder)
  end

  def write_files!(files, folder, base),
    do: write_files!(files, path(folder, base))

  def write_files!(files, folder) do
    # create all required subfolders
    files
    |> Map.keys()
    |> create_folders(folder)

    files
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&write_file!(&1, folder))
  end

  defp write_file!([file, content], folder) do
    if content != "" do
      file
      |> to_string()
      |> path(folder)
      |> File.write!(content)
    end
  end

  defp create_folders(files, folder) do
    files
    |> Enum.map(&to_string/1)
    |> Enum.filter(&String.contains?(&1, "/"))
    |> Enum.map(&Regex.replace(~r/\/[^\/]*$/, &1, ""))
    |> Enum.uniq()
    |> Enum.map(&init!(&1, folder))
  end

  def path(folder, base),
    do: base <> "/" <> folder
end
