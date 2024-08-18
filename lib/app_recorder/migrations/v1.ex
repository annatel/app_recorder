defmodule AppRecorder.Migrations.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_sequences_table()
  end

  def down do
    drop_sequences_table()
  end

  defp create_sequences_table() do
    if AppRecorder.with_sequence?() do
      create table(:app_recorder_sequences) do
        add(:name, :string, null: false)
        add(:value, :bigint, null: false, default: 0)
      end

      create(unique_index(:app_recorder_sequences, [:name]))

      execute("INSERT INTO app_recorder_sequences(name, value) VALUES ('events', 0)")

      case repo().__adapter__() do
        Ecto.Adapters.Postgres ->
          execute("""
          create or replace function app_recorder_nextval_gapless_sequence(in_sequence_name text)
          returns bigint
          language plpgsql
          as
          $$
          declare
            next_value bigint := 1;
          begin
            update app_recorder_sequences
            set value = value + 1
            returning value into next_value;

            return next_value;
          end;
          $$
          """)

        Ecto.Adapters.MyXQL ->
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
      end
    end
  end

  defp drop_sequences_table do
    drop(table(:app_recorder_sequences))
  end
end
