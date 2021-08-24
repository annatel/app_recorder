defmodule AppRecorder.Migrations.OutgoingRequests.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter table(:app_recorder_outgoing_requests) do
      modify(:response_body, :text)
    end
  end
end
