defmodule AppRecorder.OutgoingRequests do
  @moduledoc """
  The OutgoingRequests context.
  """
  alias AppRecorder.RequestId
  alias AppRecorder.OutgoingRequests.{OutgoingRequest, OutgoingRequestQueryable}

  @doc ~S"""
  List all outgoing_requests
  """
  @spec list_outgoing_requests(keyword) :: [Event.t()]
  def list_outgoing_requests(opts \\ []) do
    try do
      opts |> outgoing_request_queryable() |> AppRecorder.repo().all()
    rescue
      Ecto.Query.CastError -> []
    end
  end

  @spec paginate_outgoing_requests(pos_integer, pos_integer, keyword) :: %{
          data: [OutgoingRequest.t()],
          total: integer,
          page_size: integer,
          page_number: integer
        }
  def paginate_outgoing_requests(page_size, page_number, opts \\ [])
      when is_integer(page_number) and is_integer(page_size) do
    try do
      query = opts |> outgoing_request_queryable()

      requests =
        query
        |> OutgoingRequestQueryable.paginate(page_size, page_number)
        |> AppRecorder.repo().all()

      %{
        data: requests,
        page_number: page_number,
        page_size: page_size,
        total: AppRecorder.repo().aggregate(query, :count, :id)
      }
    rescue
      Ecto.Query.CastError ->
        %{data: [], page_number: page_number, page_size: page_size, total: 0}
    end
  end

  @spec record_outgoing_request!(map) :: OutgoingRequest.t()
  def record_outgoing_request!(attrs) when is_map(attrs) do
    attrs =
      attrs
      |> Map.merge(%{
        id: RequestId.generate_request_id("out_req")
      })

    %OutgoingRequest{}
    |> OutgoingRequest.create_changeset(attrs)
    |> AppRecorder.repo().insert!()
  end

  @spec update_outgoing_request!(OutgoingRequest.t(), map) :: OutgoingRequest.t()
  def update_outgoing_request!(%OutgoingRequest{} = request, attrs) when is_map(attrs) do
    request
    |> OutgoingRequest.update_changeset(attrs)
    |> AppRecorder.repo().update!()
  end

  @spec get_outgoing_request(binary) :: OutgoingRequest.t() | nil
  def get_outgoing_request(id) when is_binary(id) do
    try do
      [filters: [id: id]]
      |> outgoing_request_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  defp outgoing_request_queryable(opts) do
    filters = Keyword.get(opts, :filters, [])
    order_bys = Keyword.get(opts, :order_by_fields, desc: :id)

    OutgoingRequestQueryable.queryable()
    |> OutgoingRequestQueryable.filter(filters)
    |> OutgoingRequestQueryable.order_by(order_bys)
  end
end
