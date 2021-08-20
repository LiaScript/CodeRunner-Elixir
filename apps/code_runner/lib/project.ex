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


  def isImage(filename) do
    String.ends_with?(filename, ".png")
    || String.ends_with?(filename, ".bmp")
    || String.ends_with?(filename, ".jpg")
    || String.ends_with?(filename, ".git")
    || String.ends_with?(filename, ".tif")
    || String.ends_with?(filename, ".svg")
  end

  def findImages(folder, base) do
    dir = path(folder, base)

    dir
    |> File.ls!
    |> Enum.filter(&(isImage(&1)))
    |> Enum.map(&{&1, File.stat!(dir <> &1).ctime})
    |> Enum.sort(fn {_, time1}, {_, time2} -> time1 <= time2 end)
    |> Enum.map(fn {file, _} ->
        filename = dir <> "/" <> file

        %{:file => file,
          :data =>
          "data:image/" <> Path.extname(file)  <> ";base64," <>
          (filename
            |>File.read!
            |> Base.encode64
          )}
       end)
  end


end
