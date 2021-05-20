defmodule AppRecorder.TestRepo do
  use Ecto.Repo,
    otp_app: :app_recorder,
    adapter: Ecto.Adapters.MyXQL
end
