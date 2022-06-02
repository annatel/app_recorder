defmodule AppRecorder.Migrations.Events.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_event_related_resources_table()
  end

  def down do
    drop_event_related_resources_table()
  end

  defp create_event_related_resources_table do
    create table(:app_recorder_event_related_resources) do
      add(
        :event_id,
        references(:app_recorder_events, on_delete: :nothing, type: AppRecorder.primary_key_type()),
        null: false
      )

      add(:resource_id, :string, null: false)
      add(:resource_object, :string, null: false)

      if AppRecorder.with_livemode?(), do: add(:livemode, :boolean, null: false)

      timestamps(updated_at: false)
    end

    create(index(:app_recorder_event_related_resources, [:event_id]))
    create(index(:app_recorder_event_related_resources, [:event_id, :id]))
    create(index(:app_recorder_event_related_resources, [:resource_id]))
    create(index(:app_recorder_event_related_resources, [:resource_object]))

    if AppRecorder.with_livemode?() do
      create(index(:app_recorder_event_related_resources, [:livemode]))

      create(
        unique_index(
          :app_recorder_event_related_resources,
          [
            :event_id,
            :resource_id,
            :resource_object,
            :livemode
          ],
          name: :arerr_event_id_rid_robject_livemode
        )
      )
    else
      create(
        unique_index(
          :app_recorder_event_related_resources,
          [:event_id, :resource_id, :resource_object],
          name: :arerr_event_id_rid_robject
        )
      )
    end
  end

  defp drop_event_related_resources_table do
    drop(table(:app_recorder_event_related_resources))
  end
end
