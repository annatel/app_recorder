defmodule AppRecorder.Events.EventTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.Events.Event

  describe "changeset/2" do
    test "only permitted_keys are casted" do
      event_params = params_for(:event, livemode: false, data: %{key: "value"})

      changeset =
        Event.changeset(
          %Event{},
          Map.merge(event_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :created_at in changes_keys
      assert :data in changes_keys
      assert :livemode in changes_keys
      assert :origin in changes_keys
      assert :owner_id in changes_keys
      assert :request_id in changes_keys
      assert :resource_id in changes_keys
      assert :resource_object in changes_keys
      assert :sequence in changes_keys
      assert :source in changes_keys
      assert :source_event_id in changes_keys
      assert :type in changes_keys
      refute :new_key in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      event_params = params_for(:event)

      changeset = Event.changeset(%Event{}, event_params)

      assert changeset.valid?

      assert get_field(changeset, :created_at) == event_params.created_at
      assert get_field(changeset, :data) == event_params.data
      assert get_field(changeset, :livemode) == event_params.livemode
      assert get_field(changeset, :origin) == event_params.origin
      assert get_field(changeset, :owner_id) == event_params.owner_id
      assert get_field(changeset, :request_id) == event_params.request_id
      assert get_field(changeset, :resource_id) == event_params.resource_id
      assert get_field(changeset, :resource_object) == event_params.resource_object
      assert get_field(changeset, :sequence) == event_params.sequence
      assert get_field(changeset, :source) == event_params.source
      assert get_field(changeset, :source_event_id) == event_params.source_event_id
      assert get_field(changeset, :type) == event_params.type
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = Event.changeset(%Event{}, %{data: nil})

      refute changeset.valid?
      assert %{created_at: ["can't be blank"]} = errors_on(changeset)
      assert %{data: ["can't be blank"]} = errors_on(changeset)
      assert %{owner_id: ["can't be blank"]} = errors_on(changeset)
      assert %{sequence: ["can't be blank"]} = errors_on(changeset)
      assert %{type: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
