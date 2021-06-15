defmodule AppRecorder.Migrations.Events.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_events_table()
  end

  def down do
    drop_events_table()
  end

  defp create_events_table do
    primary_key_type_id? = AppRecorder.primary_key_type() == :id

    create table(:app_recorder_events, primary_key: primary_key_type_id?) do
      if not primary_key_type_id?, do: add(:id, AppRecorder.primary_key_type(), primary_key: true)

      add(
        elem(AppRecorder.owner_id_field(:migration), 0),
        elem(AppRecorder.owner_id_field(:migration), 1),
        null: false
      )

      add(:api_version, :string, null: false)
      add(:created_at, :utc_datetime, null: false)
      add(:data, :map, null: false)
      add(:idempotency_key, :string, null: true)

      if AppRecorder.with_livemode?(), do: add(:livemode, :boolean, null: false)

      add(:origin, :string, null: true)
      add(:request_id, :binary, null: true)
      add(:request_idempotency_key, :string, null: true)
      add(:resource_id, :string, null: true)
      add(:resource_object, :string, null: true)

      if AppRecorder.with_sequence?(), do: add(:sequence, :integer, null: false)

      add(:source, :string, null: true)
      add(:source_event_id, AppRecorder.primary_key_type(), null: true)
      add(:type, :string, null: false)

      timestamps(updated_at: false)
      add(:object, :string, null: false, default: "event")
    end

    create(index(:app_recorder_events, [elem(AppRecorder.owner_id_field(:migration), 0)]))
    create(index(:app_recorder_events, [:created_at]))

    if AppRecorder.with_livemode?(), do: create(index(:app_recorder_events, [:livemode]))
    create(index(:app_recorder_events, [:origin]))

    create(index(:app_recorder_events, [:resource_object]))
    create(index(:app_recorder_events, [:resource_id]))

    if AppRecorder.with_sequence?(), do: create(index(:app_recorder_events, [:sequence]))
    create(index(:app_recorder_events, [:source]))
    create(index(:app_recorder_events, [:source_event_id]))
    create(index(:app_recorder_events, [:type]))
  end

  defp drop_events_table do
    drop(table(:app_recorder_events))
  end
end
