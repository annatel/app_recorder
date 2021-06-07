defmodule AppRecorder.Events do
  @moduledoc false

  require Ecto.Query

  alias Ecto.Multi

  alias AppRecorder.Sequences
  alias AppRecorder.Events.{Event, EventQueryable}

  @default_page_number 1
  @default_page_size 100

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

  @spec record_event!(map, keyword) :: Event.t()
  def record_event!(attrs, opts \\ []) do
    allowed_event_types = Keyword.get(opts, :allowed_event_types)

    {:ok, event} =
      AppRecorder.repo().transaction(fn repo ->
        attrs =
          attrs
          |> Map.merge(%{
            created_at: DateTime.utc_now(),
            idempotentcy_key: Logger.metadata()[:idempotentcy_key],
            request_id: Logger.metadata()[:request_id]
          })
          |> maybe_put_sequence()

        %Event{}
        |> Event.changeset(attrs)
        |> maybe_validate_event_type(allowed_event_types)
        |> repo.insert!()
      end)

    event
  end

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
    [filters: [id: id]]
    |> event_queryable()
    |> AppRecorder.repo().one()
  end

  @spec get_event!(binary) :: Event.t()
  def get_event!(id) when is_binary(id) do
    [filters: [id: id]]
    |> event_queryable()
    |> AppRecorder.repo().one!()
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
      do: Map.put(attrs, :sequence, Sequences.next_value!(:events)),
      else: attrs
  end
end
