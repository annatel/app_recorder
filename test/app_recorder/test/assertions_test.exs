defmodule AppRecorder.Test.AssertionsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  import AppRecorder.Test.Assertions

  describe "assert_event_recorded/0" do
    test "when the event is found" do
      insert!(:event)

      assert_event_recorded()
    end

    test "count option" do
      insert!(:event)

      message =
        %ExUnit.AssertionError{
          message: "Expected 2 events, got 1"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_event_recorded(2) end
    end

    test "when the event is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected 1 event, got 0"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_event_recorded() end
    end
  end

  describe "assert_event_recorded/1" do
    test "when the event is found" do
      %{resource_id: resource_id} = insert!(:event)
      insert!(:event)

      assert_event_recorded(%{resource_id: resource_id})
    end

    test "when the event is found according to related_resource" do
      %{related_resources: [%{resource_id: related_resource_id}]} = insert!(:event)
      insert!(:event)

      assert_event_recorded(%{related_resource_id: related_resource_id})
    end

    test "when the event is not found" do
      message =
        %ExUnit.AssertionError{
          message: "Expected 1 event with attributes %{resource_id: \"resource_id\"}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(%{resource_id: "resource_id"})
      end
    end

    test "count option" do
      %{resource_id: resource_id} = insert!(:event)
      insert!(:event, resource_id: resource_id)

      message =
        %ExUnit.AssertionError{
          message: "Expected 1 event with attributes %{resource_id: \"#{resource_id}\"}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(1, %{resource_id: resource_id})
      end
    end

    test "when data is specified" do
      %{resource_id: resource_id, data: data} = insert!(:event)
      insert!(:event)

      assert_event_recorded(%{
        resource_id: resource_id,
        data: data |> Recase.Enumerable.stringify_keys()
      })
    end

    test "when data is specified but value does not match" do
      %{data: %{key: "value"}} = insert!(:event)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 event with attributes %{data: %{\"key\" => \"wrong_value\"}}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(%{data: %{"key" => "wrong_value"}})
      end
    end

    test "when data is specified but key does not match" do
      %{data: %{key: "value"}} = insert!(:event)
      insert!(:event)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 event with attributes %{data: %{\"key\" => \"value\", \"wrong_key\" => \"whatever\"}}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(%{data: %{"key" => "value", "wrong_key" => "whatever"}})
      end
    end

    test "with data, count option" do
      %{data: %{key: "value"}} = insert!(:event)
      insert!(:event, data: %{key: "value"})

      message =
        %ExUnit.AssertionError{
          message: "Expected 1 event with attributes %{data: %{\"key\" => \"value\"}}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(1, %{data: %{"key" => "value"}})
      end
    end
  end

  describe "assert_outgoing_request_recorded/0" do
    test "when the event is found" do
      insert!(:outgoing_request)

      assert_outgoing_request_recorded()
    end

    test "when the outgoing_request is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected 1 outgoing_request, got 0"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_outgoing_request_recorded() end
    end

    test "count option" do
      insert!(:outgoing_request)

      message =
        %ExUnit.AssertionError{message: "Expected 2 outgoing_requests, got 1"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_outgoing_request_recorded(2) end
    end
  end

  describe "assert_outgoing_request_recorded/1" do
    test "when the outgoing_request is found" do
      %{destination: destination} = insert!(:outgoing_request)

      assert_outgoing_request_recorded(%{destination: destination})
    end

    test "when the outgoing_request is not found" do
      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 outgoing_request with attributes %{destination: \"destination\"}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_outgoing_request_recorded(%{destination: "destination"})
      end
    end

    test "count option" do
      %{destination: destination} = insert!(:outgoing_request)
      insert!(:outgoing_request, destination: destination)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 outgoing_request with attributes %{destination: \"#{destination}\"}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_outgoing_request_recorded(1, %{destination: destination})
      end
    end
  end
end
