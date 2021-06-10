defmodule AppRecorder.Migrations.Requests.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_requests_table()
  end

  def down do
    drop_requests_table()
  end

  defp create_requests_table do
    create table(:app_recorder_requests, primary_key: false) do
      if repo().__adapter__() == Ecto.Adapters.Postgres do
        add(:id, :bytea, primary_key: true)
      else
        add(:id, :binary, primary_key: true, size: 15)
      end

      add(elem(AppRecorder.owner_id_field(), 0), elem(AppRecorder.owner_id_field(), 1),
        null: false
      )

      add(:created_at, :utc_datetime, null: false)
      add(:idempotency_key, :string, null: true)

      if AppRecorder.with_livemode?(), do: add(:livemode, :boolean, null: false)

      add(:request_data, :map, null: false)
      add(:response_data, :map, null: true)

      add(:source, :string, null: true)
      add(:success, :boolean, null: true)

      timestamps()
      add(:object, :string, null: false, default: "request")
    end

    create(index(:app_recorder_requests, [elem(AppRecorder.owner_id_field(), 0)]))
    create(index(:app_recorder_requests, [:created_at]))
    create(index(:app_recorder_requests, [:idempotency_key]))

    if AppRecorder.with_livemode?(), do: create(index(:app_recorder_requests, [:livemode]))

    if repo().__adapter__() == Ecto.Adapters.Postgres do
      create(index(:app_recorder_requests, [:request_data], using: :gin))
      create(index(:app_recorder_requests, [:response_data], using: :gin))
    end

    create(index(:app_recorder_requests, [:source]))
    create(index(:app_recorder_requests, [:success]))
  end

  defp drop_requests_table do
    drop(table(:app_recorder_requests))
  end
end
