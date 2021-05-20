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
        [resource_type: event.resource_type],
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
        [resource_type: "resource_type"],
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

      event_schema =
        Events.new_event!(%{
          owner_id: uuid(),
          resource_id: "resource_id",
          resource_type: "resource_type"
        })

      audit_event_1 = Events.record_event!(event_schema, "resource.created", %{id: "id2"})

      audit_event_2 = Events.record_event!(event_schema, "resource.created", %{id: "id2"})

      assert %Event{} = audit_event_1
      assert %Event{} = audit_event_2

      assert_in_delta DateTime.to_unix(audit_event_1.created_at), DateTime.to_unix(utc_now()), 5
      assert audit_event_1.data == %{id: "id2"}
      assert audit_event_1.livemode == event_schema.livemode
      assert audit_event_1.owner_id == event_schema.owner_id
      assert audit_event_1.request_id == "request_id"
      assert audit_event_1.resource_id == "resource_id"
      assert audit_event_1.resource_type == "resource_type"
      assert audit_event_1.type == "resource.created"
      assert audit_event_2.sequence > audit_event_1.sequence
    end

    test "when data is invalid, raises an Ecto.InvalidChangesetError" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Events.record_event!(%Event{}, "resource.created", %{id: "resource_id"})
      end
    end

    test "when non-existing types and allowed_event_types is specified, raises an Ecto.InvalidChangesetError" do
      event_schema = Events.new_event!(%{owner_id: uuid()})

      assert_raise Ecto.InvalidChangesetError, fn ->
        Events.record_event!(event_schema, "event_type", %{id: "resource_id"},
          allowed_event_types: []
        )
      end
    end
  end

  describe "multi/4" do
    test "create a multi operation with params" do
      Logger.metadata(request_id: "request_id")
      event_schema = Events.new_event!(%{owner_id: uuid()})

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(event_schema, "resource.created", %{id: "resource_id"})

      assert %Ecto.Multi{} = multi

      assert {:ok, %{record_event: %Event{} = audit_event}} = TestRepo.transaction(multi)

      assert_in_delta DateTime.to_unix(audit_event.created_at), DateTime.to_unix(utc_now()), 5
      assert audit_event.data == %{id: "resource_id"}
      assert audit_event.livemode == event_schema.livemode
      assert audit_event.owner_id == event_schema.owner_id
      assert audit_event.request_id == "request_id"
      assert is_nil(audit_event.resource_id)
      assert is_nil(audit_event.resource_type)
      assert audit_event.type == "resource.created"
    end

    test "creates an ecto multi operation with a function" do
      event_schema = Events.new_event!(%{owner_id: uuid()})
      any_schema = Event.changeset(%Event{}, params_for(:event))

      multi =
        Ecto.Multi.new()
        |> Ecto.Multi.insert(:any_schema, any_schema)
        |> Events.record_event_multi(
          event_schema,
          "resource.created",
          fn event_schema, changes ->
            assert %Event{} = event_schema
            assert %{any_schema: %Event{}} = changes

            %{event_schema | data: %{id: changes.any_schema.id}}
          end
        )

      assert {:ok, %{record_event: %Event{} = audit_event, any_schema: any_schema}} =
               TestRepo.transaction(multi)

      assert audit_event.data == %{id: any_schema.id}
      assert audit_event.type == "resource.created"
    end

    test "when non-existing types and allowed_event_types is specified, returns a changeset error" do
      event_schema = Events.new_event!(%{owner_id: uuid()})

      multi =
        Ecto.Multi.new()
        |> Events.record_event_multi(event_schema, "resource.created", %{id: "resource_id"},
          allowed_event_types: []
        )

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
