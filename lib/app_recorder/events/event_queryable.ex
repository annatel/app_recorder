defmodule AppRecorder.Events.EventQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Events.Event,
    searchable_fields: [:data, :ref]

  import Ecto.Query, only: [select: 2, where: 3]

  alias AppRecorder.Events.RelatedResource

  defp filter_by_field(queryable, {:related_resource_id, value}) do
    event_ids_query =
      RelatedResource
      |> AntlUtilsEcto.Query.where(:resource_id, value)
      |> select([:event_id])

    queryable
    |> where([event], event.id in subquery(event_ids_query))
  end

  defp filter_by_field(queryable, {:related_resource_object, value}) do
    event_ids_query =
      RelatedResource
      |> AntlUtilsEcto.Query.where(:resource_object, value)
      |> select([:event_id])

    queryable
    |> where([event], event.id in subquery(event_ids_query))
  end
end
