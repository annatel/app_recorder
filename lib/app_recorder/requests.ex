defmodule AppRecorder.Requests do
  @moduledoc """
  The requests context.
  """

  import Ecto.Query, only: [order_by: 2]

  alias AppRecorder.Requests.{Request, RequestQueryable}

  @default_order_by [desc: :id]
  @default_page_number 1
  @default_page_size 100

  @spec list_requests(keyword) :: %{data: [Request.t()], total: integer}
  def list_requests(opts \\ []) do
    page_number = Keyword.get(opts, :page_number, @default_page_number)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    order_by_fields = list_order_by_fields(opts)

    query = request_queryable(opts)

    count = query |> AppRecorder.repo().aggregate(:count, :id)

    requests =
      query
      |> order_by(^order_by_fields)
      |> RequestQueryable.paginate(page_number, page_size)
      |> AppRecorder.repo().all()

    %{data: requests, total: count}
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

    RequestQueryable.queryable()
    |> RequestQueryable.filter(filters)
  end

  defp list_order_by_fields(opts) do
    Keyword.get(opts, :order_by_fields, [])
    |> case do
      [] -> @default_order_by
      [_ | _] = order_by_fields -> order_by_fields
    end
  end
end
