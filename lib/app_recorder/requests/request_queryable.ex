defmodule AppRecorder.Requests.RequestQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Requests.Request

  import Ecto.Query, only: [preload: 2, select: 2, where: 3]

  alias AppRecorder.Requests.RelatedResource

  defp include_assoc(queryable, :related_resources) do
    queryable |> preload([:related_resources])
  end

  defp filter_by_field(queryable, {:related_resource_id, value}) do
    request_ids_query =
      RelatedResource
      |> AntlUtilsEcto.Query.where(:resource_id, value)
      |> select([:request_id])

    queryable
    |> where([request], request.id in subquery(request_ids_query))
  end

  defp filter_by_field(queryable, {:related_resource_object, value}) do
    request_ids_query =
      RelatedResource
      |> AntlUtilsEcto.Query.where(:resource_object, value)
      |> select([:request_id])

    queryable
    |> where([request], request.id in subquery(request_ids_query))
  end
end
