defmodule OrderedCollections.MixProject do
  use Mix.Project

  def project do
    [
      app: :ordered_collections,
      version: "0.3.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "SortedMap and SortedSet implementations for Elixir",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/jeffreybaird/ordered_collections"
      },
      maintainers: ["Jeffrey Baird"]
    ]
  end
end
