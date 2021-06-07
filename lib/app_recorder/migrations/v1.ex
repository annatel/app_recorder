defmodule AppRecorder.Migrations.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_sequences_table()
    create_events_table()
  end

  def down do
    drop_events_table()
    drop_sequences_table()
  end

  defp create_sequences_table() do
    if AppRecorder.with_sequence?() do
      create table(:app_recorder_sequences, primary: false) do
        add(:name, :string, null: false)
        add(:value, :bigint, null: false, default: 0)
      end

      create(unique_index(:app_recorder_sequences, [:name]))

      execute("""
      DROP FUNCTION IF EXISTS app_recorder_nextval_gapless_sequence;
      """)

      execute("""
      CREATE FUNCTION app_recorder_nextval_gapless_sequence(in_sequence_name CHAR(255))
      RETURNS INTEGER DETERMINISTIC
      BEGIN
        UPDATE app_recorder_sequences SET value = LAST_INSERT_ID(value+1) WHERE name = in_sequence_name;
        RETURN LAST_INSERT_ID();
      end;
      """)

      execute("INSERT INTO app_recorder_sequences(name, value) VALUES ('events', 0)")
    end
  end

  defp create_events_table do
    create table(:app_recorder_events, primary_key: false) do
      if AppRecorder.use_uuid_as_primary_key?() do
        add(:id, :binary_id, primary_key: true)
      else
        add(:id, :id, primary_key: true)
      end

      add(AppRecorder.owner_id_field_name(), AppRecorder.owner_id_field_type(), null: false)

      add(:api_version, :string, null: false)
      add(:created_at, :utc_datetime, null: false)
      add(:data, :map, null: false)
      add(:idempotency_key, :string, null: true)

      if AppRecorder.with_livemode?() do
        add(:livemode, :boolean, null: false)
      end

      add(:request_id, :binary, null: true)
      add(:resource_id, :string, null: true)
      add(:resource_object, :string, null: true)

      if AppRecorder.with_sequence?() do
        add(:sequence, :integer, null: false)
      end

      add(:type, :string, null: false)

      timestamps(updated_at: false)
      add(:object, :string, default: "event")
    end

    if AppRecorder.with_livemode?() do
      create(index(:app_recorder_events, [:livemode]))
    end

    if AppRecorder.with_sequence?() do
      create(index(:app_recorder_events, [:sequence]))
    end

    create(index(:app_recorder_events, [:created_at]))
    create(index(:app_recorder_events, [AppRecorder.owner_id_field_name()]))
    create(index(:app_recorder_events, [:resource_object, :resource_id]))
    create(index(:app_recorder_events, [:type]))
  end

  defp drop_events_table do
    drop(table(:app_recorder_events))
  end

  defp drop_sequences_table do
    drop(table(:app_recorder_sequences))
  end
end
