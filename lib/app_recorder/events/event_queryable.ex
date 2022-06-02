defmodule AppRecorder.Events.EventQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Events.Event,
    searchable_fields: [:data, :ref]

  import Ecto.Query, only: [preload: 2, where: 3]

  alias AppRecorder.Events

  defp include_assoc(queryable, :related_resources) do
    queryable |> preload([:related_resources])
  end

  defp filter_by_field(queryable, {:related_resource_id, value}) do
    event_ids =
      Events.list_related_resources(fields: [:event_id], filters: [resource_id: value])
      |> Enum.map(& &1.event_id)

    queryable
    |> where([event], event.id in ^event_ids)
    |> AntlUtilsEcto.Query.or_where(:resource_id, value)
  end

  defp filter_by_field(queryable, {:related_resource_object, value}) do
    event_ids =
      Events.list_related_resources(fields: [:event_id], filters: [resource_object: value])
      |> Enum.map(& &1.event_id)

    queryable
    |> where([event], event.id in ^event_ids)
    |> AntlUtilsEcto.Query.or_where(:resource_object, value)
  end
end
