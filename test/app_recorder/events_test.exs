defmodule AppRecorder.EventsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.TestRepo

  alias AppRecorder.Events
  alias AppRecorder.Events.Event

  describe "list_events/1" do
    test "returns the list of events ordered by the sequence descending" do
      %{id: id_1} = insert!(:event, sequence: 1)

      assert %{data: [%Event{id: ^id_1}], total: 1} = AppRecorder.list_events()
    end

    test "order_by" do
      %{id: id1} = insert!(:event, sequence: 1)
      %{id: id2} = insert!(:event, sequence: 2)

      assert %{data: [%{id: ^id2}, %{id: ^id1}]} = AppRecorder.list_events()

      assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
               Events.list_events(order_by_fields: [asc: :sequence])
    end

    test "filters" do
      event = insert!(:event)

      [
        [id: event.id],
        [livemode: event.livemode],
        [owner_id: event.owner_id],
        [request_id: event.request_id],
        [resource_id: event.resource_id],
        [resource_object: event.resource_object],
        [sequence: event.sequence],
        [type: event.type]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_event], total: 1} = Events.list_events(filters: filter)
      end)

      [
        [id: uuid()],
        [livemode: !event.livemode],
        [owner_id: uuid()],
        [request_id: "request_id"],
        [resource_id: "resource_id"],
        [resource_object: "resource_object"],
        [sequence: 0],
        [type: "type"]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [], total: 0} = Events.list_events(filters: filter)
      end)
    end
  end

  describe "record_event!/3" do
    test "when data is valid, creates an event" do
      Logger.metadata(request_id: "request_id")

      event_params = %{
        data: %{id: "id2"},
        livemode: false,
        owner_id: uuid(),
        resource_id: "resource_id",
        resource_object: "resource_object",
        type: "resource.created"
      }

      audit_event_1 = Events.record_event!(event_params)
      audit_event_2 = Events.record_event!(event_params)

      assert %Event{} = audit_event_1
      assert %Event{} = audit_event_2

      assert_in_delta DateTime.to_unix(audit_event_1.created_at), DateTime.to_unix(utc_now()), 5
      assert audit_event_1.data == %{id: "id2"}
      assert audit_event_1.livemode == event_params.livemode
      assert audit_event_1.owner_id == event_params.owner_id
      assert audit_event_1.request_id == "request_id"
      assert audit_event_1.resource_id == event_params.resource_id
      assert audit_event_1.resource_object == event_params.resource_object
      assert audit_event_1.type == event_params.type

      assert audit_event_2.sequence > audit_event_1.sequence
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
      Logger.metadata(request_id: "request_id")
      event_params = params_for(:event)

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(event_params)

      assert %Ecto.Multi{} = multi

      assert {:ok, %{record_event: %Event{} = audit_event}} = TestRepo.transaction(multi)

      assert_in_delta DateTime.to_unix(audit_event.created_at), DateTime.to_unix(utc_now()), 5
      assert audit_event.data == event_params.data
      assert audit_event.livemode == event_params.livemode
      assert audit_event.owner_id == event_params.owner_id
      assert audit_event.request_id == "request_id"
      assert audit_event.resource_id == event_params.resource_id
      assert audit_event.resource_object == event_params.resource_object
      assert audit_event.type == event_params.type
    end

    test "creates an ecto multi operation with a function" do
      event_params = params_for(:event)

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(fn _changes -> event_params end)

      assert {:ok, %{record_event: %Event{} = audit_event}} = TestRepo.transaction(multi)

      assert audit_event.data == event_params.data
      assert audit_event.type == event_params.type
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
    end
  end
end
