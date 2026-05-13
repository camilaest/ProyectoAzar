defmodule ProyectoAzar.MixProject do
  use Mix.Project

  def project do
    [
      app: :proyecto_azar,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
  [
    extra_applications: [:logger],
    mod: {ProyectoAzar.Application, []}
  ]
end

  defp deps do
    [
      {:jason, "~> 1.0"},
      {:tzdata, "~> 1.1"}
    ]
  end
end
