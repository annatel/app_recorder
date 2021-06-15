defmodule AppRecorder.Requests do
  @moduledoc """
  The requests context.
  """

  alias AppRecorder.Requests.{Request, RequestQueryable}

  @spec paginate_requests(pos_integer, pos_integer, keyword) :: %{
          data: [Request.t()],
          total: integer
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
        total: AppRecorder.repo().aggregate(query, :count, :id)
      }
    rescue
      Ecto.Query.CastError -> %{total: 0, data: []}
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

  @spec get_request(binary) :: Request.t() | nil
  def get_request(id) when is_binary(id) do
    try do
      [filters: [id: id]]
      |> request_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec get_request_by(keyword) :: Request.t() | nil
  def get_request_by(idempotency_key: idempotency_key) do
    [filters: [idempotency_key: idempotency_key]]
    |> request_queryable()
    |> AppRecorder.repo().one()
  end

  defp request_queryable(opts) do
    filters = Keyword.get(opts, :filters, [])
    order_bys = Keyword.get(opts, :order_by_fields, desc: :id)

    RequestQueryable.queryable()
    |> RequestQueryable.filter(filters)
    |> RequestQueryable.order_by(order_bys)
  end
end
