defmodule AppRecorder.Migrations.Requests.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_request_related_resources_table()
  end

  def down do
    drop_request_related_resources_table()
  end

  defp create_request_related_resources_table do
    create table(:app_recorder_request_related_resources) do
      if repo().__adapter__() == Ecto.Adapters.Postgres do
        add(
          :request_id,
          references(:app_recorder_requests, on_delete: :nothing, type: :bytea),
          null: false
        )
      else
        add(
          :request_id,
          references(:app_recorder_requests, on_delete: :nothing, type: :binary),
          null: false,
          size: 15
        )
      end

      add(:resource_id, :string, null: false)
      add(:resource_object, :string, null: false)

      if AppRecorder.with_livemode?(), do: add(:livemode, :boolean, null: false)

      timestamps(updated_at: false)
    end

    create(index(:app_recorder_request_related_resources, [:request_id]))
    create(index(:app_recorder_request_related_resources, [:resource_id]))
    create(index(:app_recorder_request_related_resources, [:resource_object]))

    if AppRecorder.with_livemode?(),
      do: create(index(:app_recorder_request_related_resources, [:livemode]))

    create(
      unique_index(
        :app_recorder_request_related_resources,
        [
          :request_id,
          :resource_id,
          :resource_object,
          :livemode
        ],
        name: :arrrr_reqid_rid_robject_livemode
      )
    )
  end

  defp drop_request_related_resources_table do
    drop(table(:app_recorder_request_related_resources))
  end
end
