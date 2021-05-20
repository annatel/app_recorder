defmodule AppRecorder.Events do
  @moduledoc false

  require Ecto.Query

  alias Ecto.Multi

  alias AppRecorder.Sequences
  alias AppRecorder.Events.{Event, EventQueryable}

  @default_page_number 1
  @default_page_size 100
  @default_order_by_fields [desc: :sequence]

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
      |> Ecto.Query.order_by(^order_by_fields)
      |> AppRecorder.repo().all()

    %{data: events, total: count}
  end

  @spec new_event!(%{:owner_id => binary, optional(atom) => any}) :: Event.t()
  def new_event!(%{owner_id: _} = fields) do
    struct!(Event, fields)
  end

  @spec record_event!(Event.t(), binary, map, [binary]) :: Event.t()
  def record_event!(%Event{} = event_schema, type, data, opts \\ []) do
    {:ok, event} =
      AppRecorder.repo().transaction(fn repo ->
        event_schema
        |> Map.put(:sequence, Sequences.next_value!(:events))
        |> build!(type, data, opts)
        |> repo.insert!()
      end)

    event
  end

  @spec record_event_multi(Ecto.Multi.t(), Event.t(), binary, map | function, keyword) ::
          Ecto.Multi.t()
  def record_event_multi(multi, event_schema, type, mixed, opts \\ [])

  def record_event_multi(multi, %Event{} = event_schema, type, fun, opts)
      when is_function(fun, 2) do
    Ecto.Multi.run(multi, :record_event, fn _repo, changes ->
      {:ok, record_event!(fun.(event_schema, changes), type, %{}, opts)}
    end)
  end

  def record_event_multi(multi, %Event{} = event_schema, type, data, opts)
      when is_binary(type) and is_map(data) do
    Multi.run(multi, :record_event, fn _repo, _changes ->
      {:ok, record_event!(event_schema, type, data, opts)}
    end)
  end

  @spec get_event(binary) :: Event.t() | nil
  def get_event(id) when is_binary(id) do
    [filters: [id: id]]
    |> event_queryable()
    |> AppRecorder.repo().one()
  end

  defp build!(%Event{} = event, type, data, opts)
       when is_binary(type) and is_map(data) and is_list(opts) do
    allowed_event_types = Keyword.get(opts, :allowed_event_types)

    Event.changeset(event, %{
      created_at: DateTime.utc_now(),
      data: Map.merge(event.data || %{}, data),
      request_id: Logger.metadata()[:request_id],
      type: type
    })
    |> maybe_validate_event_type(allowed_event_types)
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
      [] -> @default_order_by_fields
      [_ | _] = order_by_fields -> order_by_fields
    end
  end
end
