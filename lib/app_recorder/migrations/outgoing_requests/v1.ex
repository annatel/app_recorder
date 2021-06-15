defmodule AppRecorder.Migrations.OutgoingRequests.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_outgoing_requests_table()
  end

  def down do
    drop_outgoing_requests_table()
  end

  defp create_outgoing_requests_table do
    create table(:app_recorder_outgoing_requests, primary_key: false) do
      if repo().__adapter__() == Ecto.Adapters.Postgres do
        add(:id, :bytea, primary_key: true)
      else
        add(:id, :binary, primary_key: true, size: 15)
      end

      add(:destination, :string, null: false)
      add(:client_error_message, :string, null: true)
      add(:requested_at, :utc_datetime, null: false)
      add(:request_body, :string, null: true)
      add(:request_headers, :map, null: true)
      add(:request_method, :string, null: false)
      add(:request_url, :string, null: false)
      add(:responded_at, :utc_datetime, null: true)
      add(:response_http_status, :int, null: true)
      add(:response_headers, :map, null: true)
      add(:response_body, :string, null: true)
      add(:source, :string, null: false)
      add(:success, :boolean, null: true)

      timestamps()
      add(:object, :string, null: false, default: "outgoing_request")
    end

    create(index(:app_recorder_outgoing_requests, [:destination]))

    create(index(:app_recorder_outgoing_requests, [:requested_at]))
    create(index(:app_recorder_outgoing_requests, [:request_method]))
    create(index(:app_recorder_outgoing_requests, [:request_url]))
    create(index(:app_recorder_outgoing_requests, [:responded_at]))
    create(index(:app_recorder_outgoing_requests, [:response_http_status]))
    create(index(:app_recorder_outgoing_requests, [:source]))
    create(index(:app_recorder_outgoing_requests, [:success]))
  end

  defp drop_outgoing_requests_table do
    drop(table(:app_recorder_outgoing_requests))
  end
end
