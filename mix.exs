defmodule AppRecorder.MixProject do
  use Mix.Project

  @source_url "https://github.com/annatel/app_recorder"
  @version "0.4.3"

  def project do
    [
      app: :app_recorder,
      version: version(),
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: test_coverage(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ecto_sql, "~> 3.6"},
      {:myxql, "~> 0.4.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:shortcode, "~> 0.7.0"},
      {:antl_utils_ecto, "~> 2.4"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.0"},
      {:recase, "~> 0.7"},
      {:padlock, "~> 0.2"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_coverage() do
    [
      ignore_modules: [AppRecorder.Migrations, AppRecorder.Migrations.V1]
    ]
  end

  defp aliases do
    [
      "app.version": &display_app_version/1,
      test: ["ecto.setup", "test"],
      "ecto.setup": [
        "ecto.create --quiet -r AppRecorder.TestRepo",
        "ecto.migrate -r AppRecorder.TestRepo"
      ],
      "ecto.reset": ["ecto.drop -r AppRecorder.TestRepo", "ecto.setup"]
    ]
  end

  defp description() do
    "Record events"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end

  defp version(), do: @version
  defp display_app_version(_), do: Mix.shell().info(version())
end
