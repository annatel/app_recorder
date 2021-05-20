import Config

if(Mix.env() == :test) do
  config :logger, level: System.get_env("EX_LOG_LEVEL", "warn") |> String.to_atom()

  config :app_recorder, ecto_repos: [AppRecorder.TestRepo]

  config :app_recorder, AppRecorder.TestRepo,
    url: System.get_env("APP_RECORDER__DATABASE_TEST_URL"),
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :app_recorder,
    repo: AppRecorder.TestRepo
end
