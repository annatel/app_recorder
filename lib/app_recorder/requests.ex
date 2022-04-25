defmodule AppRecorder.Requests do
  @moduledoc """
  The requests context.
  """

  alias AppRecorder.Requests.{Request, RequestQueryable}

  @doc ~S"""
  List all events
  """
  @spec list_requests(keyword) :: [Request.t()]
  def list_requests(opts \\ []) do
    try do
      opts |> request_queryable() |> AppRecorder.repo().all()
    rescue
      Ecto.Query.CastError -> []
    end
  end

  @spec paginate_requests(pos_integer, pos_integer, keyword) :: %{
          data: [Request.t()],
          total: integer,
          page_size: integer,
          page_number: integer
        }
  def paginate_requests(page_size, page_number, opts \\ [])
      when is_integer(page_number) and is_integer(page_size) do
    try do
      query = opts |> request_queryable()

      requests =
        query
        |> RequestQueryable.paginate(page_size, page_number)
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

  @spec record_request!(map) :: Request.t()
  def record_request!(attrs) when is_map(attrs) do
    %Request{}
    |> Request.create_changeset(attrs)
    |> AppRecorder.repo().insert!()
  end

  @spec update_request!(Request.t(), map) :: Request.t()
  def update_request!(%Request{} = request, attrs) when is_map(attrs) do
    request
    |> Request.update_changeset(attrs)
    |> AppRecorder.repo().update!()
  end

  @spec get_request(binary, keyword) :: Request.t() | nil
  def get_request(id, opts \\ []) when is_binary(id) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:id, id)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> request_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec get_request_by(keyword, keyword) :: Request.t() | nil
  def get_request_by([idempotency_key: idempotency_key], opts \\ []) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:idempotency_key, idempotency_key)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> request_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  defp request_queryable(opts) do
    filters = Keyword.get(opts, :filters, [])

    includes =
      Keyword.get(opts, :includes, []) |> Enum.concat([:related_resources]) |> Enum.uniq()

    order_bys = Keyword.get(opts, :order_by_fields, desc: :id)

    RequestQueryable.queryable()
    |> RequestQueryable.filter(filters)
    |> RequestQueryable.include(includes)
    |> RequestQueryable.order_by(order_bys)
  end
end
