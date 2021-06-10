defmodule AppRecorder.Events do
  @moduledoc """
  The requests context.
  """

  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi

  alias AppRecorder.Events.{Event, EventQueryable}

  @default_page_number 1
  @default_page_size 100

  @doc ~S"""
  List all events
  """

  @spec list_events(keyword) :: %{data: [Event.t()], total: integer}
  def list_events(opts \\ []) do
    page_number = Keyword.get(opts, :page_number, @default_page_number)
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    order_by_fields = list_order_by_fields(opts)

    query = event_queryable(opts)

    count = query |> AppRecorder.repo().aggregate(:count, :id)

    events =
      query
      |> EventQueryable.paginate(page_number, page_size)
      |> order_by(^order_by_fields)
      |> AppRecorder.repo().all()

    %{data: events, total: count}
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
    |> Multi.run(:lock_idempotency_key, fn
      _, %{idempotency_key: nil} -> {:ok, nil}
      _, %{idempotency_key: idempotency_key} -> {:ok, Padlock.Mutexes.lock!(idempotency_key)}
    end)
    |> Multi.run(:original_event, fn
      _, %{idempotency_key: nil} ->
        {:ok, nil}

      _, %{idempotency_key: idempotency_key} ->
        {:ok, get_event_by(idempotency_key: idempotency_key)}
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

  @spec get_event(binary) :: Event.t() | nil
  def get_event(id) when is_binary(id) do
    try do
      [filters: [id: id]]
      |> event_queryable()
      |> AppRecorder.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec get_event!(binary) :: Event.t()
  def get_event!(id) when is_binary(id) do
    [filters: [id: id]]
    |> event_queryable()
    |> AppRecorder.repo().one!()
  end

  defp get_event_by(idempotency_key: nil), do: nil

  defp get_event_by(idempotency_key: idempotency_key) do
    [filters: [idempotency_key: idempotency_key]]
    |> event_queryable()
    |> AppRecorder.repo().one()
  end

  defp maybe_validate_event_type(%Ecto.Changeset{} = changeset, nil), do: changeset

  defp maybe_validate_event_type(%Ecto.Changeset{} = changeset, allowed_event_types)
       when is_list(allowed_event_types) do
    changeset
    |> Ecto.Changeset.validate_inclusion(:type, allowed_event_types)
  end

  defp event_queryable(opts) do
    filters = Keyword.get(opts, :filters, [])

    EventQueryable.queryable()
    |> EventQueryable.filter(filters)
  end

  defp list_order_by_fields(opts) do
    Keyword.get(opts, :order_by_fields, [])
    |> case do
      [] -> if AppRecorder.with_sequence?(), do: [desc: :sequence], else: [desc: :id]
      [_ | _] = order_by_fields -> order_by_fields
    end
  end

  defp maybe_put_sequence(attrs) do
    if AppRecorder.with_sequence?(),
      do: Map.put(attrs, :sequence, AppRecorder.Sequences.next_value!(:events)),
      else: attrs
  end
end
