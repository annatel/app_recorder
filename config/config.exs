import Config

if(Mix.env() == :test) do
  config :logger, level: System.get_env("EX_LOG_LEVEL", "warning") |> String.to_atom()

  config :app_recorder, ecto_repos: [AppRecorder.TestRepo]

  config :app_recorder, AppRecorder.TestRepo,
    url: System.get_env("DATABASE_TEST_URL"),
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :app_recorder,
    test_repo_adapter: System.get_env("DATABASE_TEST_REPO_ADAPTER")

  config :app_recorder,
    repo: AppRecorder.TestRepo

  config :padlock,
    repo: AppRecorder.TestRepo

  config :app_recorder,
    primary_key_type: :binary_id,
    owner_id_field: [migration: {:owner_id, :binary_id}, schema: {:owner_id, :binary_id, []}],
    with_livemode?: true,
    with_sequence?: true,
    with_ref?: true
end
