defmodule AppRecorder.EventsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.TestRepo

  alias AppRecorder.Events
  alias AppRecorder.Events.Event

  describe "list_events/1" do
    test "list events" do
      %{id: id_1} = insert!(:event)

      assert [%Event{id: ^id_1}] = Events.list_events()
    end
  end

  describe "paginate_events/3" do
    test "returns the list of events ordered by the sequence descending" do
      %{id: id_1} = insert!(:event)

      assert %{data: [%Event{id: ^id_1}], total: 1} = Events.paginate_events(100, 1)
      assert %{data: [], total: 1} = Events.paginate_events(100, 2)
    end

    test "order_by" do
      %{id: id1} = insert!(:event, sequence: 1)
      %{id: id2} = insert!(:event, sequence: 2)

      assert %{data: [%{id: ^id2}, %{id: ^id1}]} = Events.paginate_events(100, 1)

      assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
               Events.paginate_events(100, 1, order_by_fields: [asc: :sequence])
    end

    test "filters" do
      %{related_resources: [related_resource]} = event = insert!(:event)

      [
        [id: event.id],
        [idempotency_key: event.idempotency_key],
        [livemode: event.livemode],
        [owner_id: event.owner_id],
        [related_resource_id: related_resource.resource_id],
        [related_resource_id: [related_resource.resource_id]],
        [related_resource_object: related_resource.resource_object],
        [request_id: event.request_id],
        [request_idempotency_key: event.request_idempotency_key],
        [resource_id: event.resource_id],
        [resource_object: event.resource_object],
        [sequence: event.sequence],
        [type: event.type]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_event], total: 1} = Events.paginate_events(100, 1, filters: filter)
      end)

      [
        [id: uuid()],
        [idempotency_key: "idempotency_key"],
        [livemode: !event.livemode],
        [owner_id: uuid()],
        [related_resource_id: "related_resource_id"],
        [related_resource_object: "related_resource_object"],
        [request_id: request_id()],
        [request_idempotency_key: "request_idempotency_key"],
        [resource_id: "resource_id"],
        [resource_object: "resource_object"],
        [sequence: 0],
        [type: "type"]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [], total: 0} = Events.paginate_events(100, 1, filters: filter)
      end)
    end

    test "search query" do
      event = insert!(:event, data: %{hello: "world"})

      assert %{data: [_], total: 1} = Events.paginate_events(100, 1, search_query: event.ref)
      assert %{data: [_], total: 1} = Events.paginate_events(100, 1, search_query: "world")

      assert %{data: [], total: 0} =
               Events.paginate_events(100, 1, search_query: event.ref <> "wrong value")

      assert %{data: [], total: 0} = Events.paginate_events(100, 1, search_query: "hello:world")
    end
  end

  describe "record_event!/3" do
    test "when data is valid, creates an event" do
      request_id = request_id("req")
      request_idempotency_key = "request_idempotency_key"
      Logger.metadata(request_id: request_id)
      Logger.metadata(request_idempotency_key: request_idempotency_key)

      %{related_resources: [related_resource_params]} =
        event_params =
        params_for(:event,
          created_at: utc_now() |> add(3600, :second),
          request_id: nil,
          sequence: 12345
        )

      event_1 = Events.record_event!(event_params)
      event_2 = Events.record_event!(params_for(:event))

      assert %Event{} = event_1
      assert %Event{} = event_2

      assert_in_delta DateTime.to_unix(event_1.created_at), DateTime.to_unix(utc_now()), 5
      assert event_1.data == event_1.data
      assert event_1.idempotency_key == event_params.idempotency_key
      assert event_1.livemode == event_params.livemode
      assert event_1.origin == event_params.origin
      assert event_1.owner_id == event_params.owner_id
      assert event_1.ref == event_params.ref
      assert [related_resource] = event_1.related_resources
      assert related_resource.resource_id == related_resource_params.resource_id
      assert related_resource.resource_object == related_resource_params.resource_object
      assert related_resource.livemode == event_params.livemode
      assert event_1.request_id == request_id
      assert event_1.request_idempotency_key == request_idempotency_key
      assert event_1.resource_id == event_params.resource_id
      assert event_1.resource_object == event_params.resource_object
      refute event_1.sequence == event_params.sequence
      assert event_1.source == event_params.source
      assert event_1.source_event_id == event_params.source_event_id
      assert event_1.type == event_params.type

      assert event_2.sequence > event_1.sequence
    end

    test "data, livemode, owner_id, ref and type are required" do
      assert_raise Ecto.InvalidChangesetError, ~r/data: \[{\"can't be blank\"/, fn ->
        Events.record_event!(%{data: nil})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/livemode: \[{\"can't be blank\"/, fn ->
        Events.record_event!(%{})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/owner_id: \[{\"can't be blank\"/, fn ->
        Events.record_event!(%{})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/ref: \[{\"can't be blank\"/, fn ->
        Events.record_event!(%{})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/type: \[{\"can't be blank\"/, fn ->
        Events.record_event!(%{})
      end
    end

    test "when an event already exists with the idempotency_key from the same source, no matter the other params, do not create a new event and returns already recorded event" do
      %{id: event_id} = event = insert!(:event)

      event_params =
        params_for(:event, idempotency_key: event.idempotency_key, source: event.source)

      assert %{id: ^event_id} = Events.record_event!(event_params)
    end

    test "when an event already exists with the idempotency_key when the source is nil, no matter the other params, do not create a new event and returns already recorded event" do
      %{id: event_id} = event = insert!(:event, source: nil)

      event_params =
        params_for(:event, idempotency_key: event.idempotency_key, source: event.source)

      assert %{id: ^event_id} = Events.record_event!(event_params)
    end

    test "when an event already exists with the idempotency_key from another source, record a new event" do
      %{id: event_id} = event = insert!(:event)
      event_params = params_for(:event, idempotency_key: event.idempotency_key)

      assert %{id: new_event_id} = Events.record_event!(event_params)
      assert new_event_id != event_id
    end

    test "request_id can be set from attrs" do
      request_id = request_id("req")
      Logger.metadata(request_id: nil)
      event_params = params_for(:event, request_id: request_id)

      assert %{request_id: ^request_id} = Events.record_event!(event_params)
    end

    test "when data is invalid, raises an Ecto.InvalidChangesetError" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Events.record_event!(%{})
      end
    end

    test "when non-existing types and allowed_event_types is specified, raises an Ecto.InvalidChangesetError" do
      event_params = params_for(:event)

      assert_raise Ecto.InvalidChangesetError, fn ->
        Events.record_event!(event_params, allowed_event_types: [])
      end
    end
  end

  describe "multi/4" do
    test "create a multi operation with attrs" do
      request_id = request_id("req")
      request_idempotency_key = "request_idempotency_key"
      Logger.metadata(request_id: request_id)
      Logger.metadata(request_idempotency_key: request_idempotency_key)

      event_params = params_for(:event, request_id: nil)

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(event_params)

      assert %Ecto.Multi{} = multi

      assert {:ok, %{record_event: %Event{} = event}} = TestRepo.transaction(multi)

      assert_in_delta DateTime.to_unix(event.created_at), DateTime.to_unix(utc_now()), 5
      assert event.data == event_params.data
      assert event.idempotency_key == event_params.idempotency_key
      assert event.livemode == event_params.livemode
      assert event.owner_id == event_params.owner_id
      assert event.request_id == request_id
      assert event.request_idempotency_key == request_idempotency_key
      assert event.resource_id == event_params.resource_id
      assert event.resource_object == event_params.resource_object
      assert event.type == event_params.type
    end

    test "creates an ecto multi operation with a function" do
      event_params = params_for(:event)

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(fn _changes -> event_params end)

      assert {:ok, %{record_event: %Event{} = event}} = TestRepo.transaction(multi)

      assert event.data == event_params.data
      assert event.type == event_params.type
    end

    test "when non-existing types and allowed_event_types is specified, returns a changeset error" do
      event_params = params_for(:event)

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(event_params, allowed_event_types: [])

      assert_raise Ecto.InvalidChangesetError, fn ->
        TestRepo.transaction(multi)
      end
    end
  end

  describe "get_event/2" do
    test "when the event exists, returns the event" do
      %{id: id} = insert!(:event)

      assert %Event{id: ^id} = Events.get_event(id)
    end

    test "when then event does not exist, returns nil" do
      assert is_nil(Events.get_event(uuid()))
      assert is_nil(Events.get_event(shortcode_uuid("evt")))
    end

    test "filters" do
      %{id: event_id} = event = insert!(:event)

      [
        [idempotency_key: event.idempotency_key],
        [livemode: event.livemode],
        [owner_id: event.owner_id],
        [request_id: event.request_id],
        [request_idempotency_key: event.request_idempotency_key],
        [resource_id: event.resource_id],
        [resource_object: event.resource_object],
        [sequence: event.sequence],
        [type: event.type]
      ]
      |> Enum.each(fn filter ->
        assert %{id: ^event_id} = Events.get_event(event_id, filters: filter)
      end)

      [
        [idempotency_key: "idempotency_key"],
        [livemode: !event.livemode],
        [owner_id: uuid()],
        [request_id: request_id()],
        [request_idempotency_key: "request_idempotency_key"],
        [resource_id: "resource_id"],
        [resource_object: "resource_object"],
        [sequence: 0],
        [type: "type"]
      ]
      |> Enum.each(fn filter ->
        assert is_nil(Events.get_event(event_id, filters: filter))
      end)
    end
  end

  describe "get_event!/2" do
    test "when the event exists, returns the event" do
      %{id: id} = insert!(:event)

      assert %Event{id: ^id} = Events.get_event!(id)
    end

    test "when then event does not exist, returns nil" do
      assert_raise Ecto.NoResultsError, fn ->
        Events.get_event!(uuid())
      end
    end
  end
end
