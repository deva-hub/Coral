defmodule Mix.Tasks.Compile.Coral do
  use Mix.Task
  require Logger

  alias Coral.Compiler.Messages

  @recursive true

  def run(_args) do
    config = Mix.Project.config()
    cmake = Keyword.get(config, :coral_cmakes) || raise_missing_cmake()

    File.mkdir_p!(priv_dir())

    Enum.map(cmake, &compile_cmake/1)

    # Workaround for a mix problem. We should REALLY get this fixed properly.
    _ =
      symlink_or_copy(
        config,
        Path.expand("priv"),
        Path.join(Mix.Project.app_path(config), "priv")
      )
  end

  defp priv_dir, do: "priv/native"

  def compile_cmake({name, config}) do
    cmake_path = Keyword.get(config, :path, "native/#{name}")
    build_mode = Keyword.get(config, :mode, :release)

    Mix.shell().info("Compiling NIF cmake #{inspect(name)} (#{cmake_path})...")

    cmake_full_path = Path.expand(cmake_path, File.cwd!())

    target_dir =
      Keyword.get(
        config,
        :target_dir,
        Path.join([Mix.Project.build_path(), "coral_cmakes", Atom.to_string(name)])
      )

    compile_command =
      make_base_command(Keyword.get(config, :cargo, :system))
      |> make_build_mode_flag(build_mode)

    [cmd_bin | args] = compile_command

    System.cmd("cmake", ["."],
      cd: cmake_full_path,
      stderr_to_stdout: true,
      into: IO.stream(:stdio, :line)
    )

    compile_return =
      System.cmd(cmd_bin, args ++ [cmake_full_path],
        cd: cmake_full_path,
        stderr_to_stdout: true,
        env: [{"CMAKE_RUNTIME_OUTPUT_DIRECTORY", target_dir} | Keyword.get(config, :env, [])],
        into: IO.stream(:stdio, :line)
      )

    case compile_return do
      {_, 0} -> nil
      {_, code} -> raise "Rust NIF compile error (rustc exit code #{code})"
    end

    {src_file, dst_file} = make_file_names(name, :lib)
    compiled_lib = Path.join([target_dir, Atom.to_string(build_mode), src_file])
    destination_lib = Path.join(priv_dir(), dst_file)

    # If the file exists already, we delete it first. This is to ensure that another
    # process, which might have the library dynamically linked in, does not generate
    # a segfault. By deleting it first, we ensure that the copy operation below does
    # not write into the existing file.
    File.rm(destination_lib)
    File.cp!(compiled_lib, destination_lib)
  end

  defp make_base_command(:system), do: ["cmake", "--build"]

  defp make_build_mode_flag(args, :release), do: args ++ ["-DCMAKE_BUILD_TYPE=Release"]
  defp make_build_mode_flag(args, :debug), do: args ++ []

  def make_file_names(base_name, :lib) do
    case :os.type() do
      {:win32, _} -> {"#{base_name}.dll", "lib#{base_name}.dll"}
      {:unix, _} -> {"lib#{base_name}.so", "lib#{base_name}.so"}
    end
  end

  def make_file_names(base_name, :bin) do
    case :os.type() do
      {:win32, _} -> {"#{base_name}.exe", "#{base_name}.exe"}
      {:unix, _} -> {base_name, base_name}
    end
  end

  def throw_error(error_descr) do
    Mix.shell().error(Messages.message(error_descr))
    raise "Compilation error"
  end

  defp raise_missing_cmake do
    Mix.raise("""
    Missing required :coral_cmakes option in mix.exs.
    """)
  end

  # https://github.com/elixir-lang/elixir/blob/b13404e913fff70e080c08c2da3dbd5c41793b54/lib/mix/lib/mix/project.ex#L553-L562
  defp symlink_or_copy(config, source, target) do
    if config[:build_embedded] do
      if File.exists?(source) do
        File.rm_rf!(target)
        File.cp_r!(source, target)
      end

      :ok
    else
      Mix.Utils.symlink_or_copy(source, target)
    end
  end
end
