defmodule Coral do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @on_load :__init__

      @cmake_opts opts

      def __init__ do
        # Remove any old modules that may be loaded so we don't get
        # :error, {:upgrade, 'Upgrade not supported by this NIF library.'}}
        :code.purge(__MODULE__)

        {so_path, load_data} = Coral.compile_config(__MODULE__, @cmake_opts)
        :erlang.load_nif(so_path, load_data)
      end
    end
  end

  @doc false
  def cmake_version, do: "3.0.0"

  @doc """
  Supported NIF API versions.
  """
  def nif_versions,
    do: [
      '2.7',
      '2.8',
      '2.9',
      '2.10',
      '2.11',
      '2.12',
      '2.13',
      '2.14'
    ]

  @doc """
  Retrieves the compile time configuration.
  """
  def compile_config(mod, opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)
    config = Application.get_env(otp_app, mod, [])

    cmake = to_string(opts[:cmake] || config[:cmake] || otp_app)
    cmake = if String.starts_with?(cmake, "lib"), do: cmake, else: "lib" <> cmake

    priv_dir = otp_app |> :code.priv_dir() |> to_string()
    load_data = opts[:load_data] || config[:load_data] || 0
    so_path = String.to_charlist("#{priv_dir}/native/#{cmake}")

    {so_path, load_data}
  end
end
