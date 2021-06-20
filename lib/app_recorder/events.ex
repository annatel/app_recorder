defmodule AppRecorder.Events do
  @moduledoc """
  The requests context.
  """

  alias Ecto.Multi

  alias AppRecorder.Events.{Event, EventQueryable}

  @doc ~S"""
  List all events
  """
  @spec list_events(keyword) :: [Event.t()]
  def list_events(opts \\ []) do
    try do
      opts |> event_queryable() |> AppRecorder.repo().all()
    rescue
      Ecto.Query.CastError -> []
    end
  end

  @doc ~S"""
  Paginate events
  """
  @spec paginate_events(pos_integer, pos_integer, keyword) :: %{
          data: [Event.t()],
          total: integer,
          page_size: integer,
          page_number: integer
        }
  def paginate_events(page_size, page_number, opts \\ [])
      when is_integer(page_number) and is_integer(page_size) do
    try do
      query = opts |> event_queryable()

      events =
        query
        |> EventQueryable.paginate(page_size, page_number)
        |> AppRecorder.repo().all()

      %{
        data: events,
        page_number: page_number,
        page_size: page_size,
        total: AppRecorder.repo().aggregate(query, :count, :id)
      }
    rescue
      Ecto.Query.CastError ->
        %{data: [], page_number: page_number, page_size: page_size, total: 0}
    end
  end

  @doc ~S"""
  Record an event

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event!(map, keyword) :: Event.t()
  def record_event!(attrs, opts \\ []) do
    allowed_event_types = Keyword.get(opts, :allowed_event_types)

    Multi.new()
    |> Multi.put(:idempotency_key, Map.get(attrs, :idempotency_key))
    |> Multi.put(:source, Map.get(attrs, :source))
    |> Multi.run(:lock_idempotency_key_by_source, fn
      _, %{idempotency_key: nil} ->
        {:ok, nil}

      _, %{idempotency_key: idempotency_key, source: source} ->
        {:ok, Padlock.Mutexes.lock!("#{source}_#{idempotency_key}")}
    end)
    |> Multi.run(:original_event, fn
      _, %{idempotency_key: nil} ->
        {:ok, nil}

      _, %{idempotency_key: idempotency_key, source: source} ->
        {:ok, get_event_by([idempotency_key: idempotency_key], filters: [source: source])}
    end)
    |> Multi.run(:event, fn
      _, %{original_event: %Event{} = event} ->
        {:ok, event}

      repo, %{original_event: nil} ->
        attrs =
          attrs
          |> Map.merge(%{
            created_at: DateTime.utc_now(),
            request_id: Map.get(attrs, :request_id) || Logger.metadata()[:request_id],
            request_idempotency_key: Logger.metadata()[:request_idempotency_key]
          })
          |> maybe_put_sequence()

        {:ok,
         %Event{}
         |> Event.changeset(attrs)
         |> maybe_validate_event_type(allowed_event_types)
         |> repo.insert!()}
    end)
    |> AppRecorder.repo().transaction()
    |> case do
      {:ok, %{event: event}} -> event
    end
  end

  @doc ~S"""
  Return an record event multi

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event_multi(Ecto.Multi.t(), map | function, keyword) :: Ecto.Multi.t()
  def record_event_multi(multi, mixed, opts \\ [])

  def record_event_multi(multi, fun, opts)
      when is_function(fun, 1) do
    Ecto.Multi.run(multi, :record_event, fn _repo, changes ->
      {:ok, record_event!(fun.(changes), opts)}
    end)
  end

  def record_event_multi(multi, attrs, opts) when is_map(attrs) do
    Multi.run(multi, :record_event, fn _repo, _changes ->
      {:ok, record_event!(attrs, opts)}
    end)
  end

  @spec get_event(binary, keyword) :: Event.t() | nil
  def get_event(id, opts \\ []) when is_binary(id) and is_list(opts) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:id, id)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> event_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec get_event!(binary, keyword) :: Event.t()
  def get_event!(id, opts \\ []) when is_binary(id) and is_list(opts) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:id, id)

    opts
    |> Keyword.put(:filters, filters)
    |> event_queryable()
    |> AppRecorder.repo().one!()
  end

  defp get_event_by([idempotency_key: nil], _), do: nil

  defp get_event_by([idempotency_key: idempotency_key], opts) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:idempotency_key, idempotency_key)

    opts
    |> Keyword.put(:filters, filters)
    |> event_queryable()
    |> AppRecorder.repo().one()
  end

  defp maybe_validate_event_type(%Ecto.Changeset{} = changeset, nil), do: changeset

  defp maybe_validate_event_type(%Ecto.Changeset{} = changeset, allowed_event_types)
       when is_list(allowed_event_types) do
    changeset
    |> Ecto.Changeset.validate_inclusion(:type, allowed_event_types)
  end

  @spec event_queryable(keyword) :: Ecto.Queryable.t()
  def event_queryable(opts) do
    filters = Keyword.get(opts, :filters, [])
    order_bys = Keyword.get(opts, :order_by_fields, default_order_by_fields())

    EventQueryable.queryable()
    |> EventQueryable.filter(filters)
    |> EventQueryable.order_by(order_bys)
  end

  defp default_order_by_fields() do
    if AppRecorder.with_sequence?(), do: [desc: :sequence], else: [desc: :id]
  end

  defp maybe_put_sequence(attrs) do
    if AppRecorder.with_sequence?(),
      do: Map.put(attrs, :sequence, AppRecorder.Sequences.next_value!(:events)),
      else: attrs
  end
end
