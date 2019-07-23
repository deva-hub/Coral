defmodule Mix.Tasks.Coral.New do
  use Mix.Task
  import Mix.Generator

  @default [
    {:eex, "default/README.md.eex", "README.md"},
    {:eex, "default/CMakeLists.txt.eex", "CMakeLists.txt"},
    {:eex, "default/src/lib.cc.eex", "src/lib.cc"}
  ]

  root = Path.join(:code.priv_dir(:coral), "templates/")

  for {format, source, _} <- @default do
    unless format == :keep do
      @external_resource Path.join(root, source)
      def render(unquote(source)), do: unquote(File.read!(Path.join(root, source)))
    end
  end

  @switches []

  def run(argv) do
    {opts, _argv, _} = OptionParser.parse(argv, switches: @switches)

    module =
      prompt(
        "This is the name of the Elixir module the NIF module will be registered to.\nModule name"
      )

    name =
      prompt_default(
        "This is the name used for the generated CMake. The default is most likely fine.\nLibrary name",
        format_module_name_as_name(module)
      )

    check_module_name_validity!(module)

    path = Path.join([File.cwd!(), "native/", name])
    new(path, module, name, opts)
  end

  def new(path, module, name, _opts) do
    module_elixir = "Elixir." <> module

    binding = [
      project_name: module_elixir,
      native_module: module_elixir,
      module: module,
      library_name: name,
      cmake_version: Coral.cmake_version()
    ]

    copy_from(path, binding, @default)

    Mix.Shell.IO.info([:green, "Ready to go! See #{path}/README.md for further instructions."])
  end

  defp check_module_name_validity!(name) do
    unless name =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/ do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp format_module_name_as_name(module_name) do
    String.replace(String.downcase(module_name), ".", "_")
  end

  defp copy_from(target_dir, binding, mapping) when is_list(mapping) do
    for {format, source, target_path} <- mapping do
      target = Path.join(target_dir, target_path)

      case format do
        :keep ->
          File.mkdir_p!(target)

        :text ->
          create_file(target, render(source))

        :eex ->
          contents = EEx.eval_string(render(source), binding, file: source)
          create_file(target, contents)
      end
    end
  end

  def prompt_default(message, default) do
    response = prompt([message, :white, " (", default, ")"])

    case response do
      "" -> default
      _ -> response
    end
  end

  def prompt(message) do
    Mix.Shell.IO.print_app()
    resp = IO.gets(IO.ANSI.format([message, :white, " > "]))
    ?\n = :binary.last(resp)
    :binary.part(resp, {0, byte_size(resp) - 1})
  end
end
