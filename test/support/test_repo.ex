defmodule AppRecorder.TestRepo do
  @test_repo_adapter Application.get_env(:app_recorder, :test_repo_adapter, "myxql")

  @test_repo_adapter_options %{
    "myxql" => Ecto.Adapters.MyXQL,
    "postgres" => Ecto.Adapters.Postgres
  }

  use Ecto.Repo,
    otp_app: :app_recorder,
    adapter: @test_repo_adapter_options[@test_repo_adapter]
end
