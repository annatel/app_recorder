defmodule AppRecorder.Test.AssertionsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  import AppRecorder.Test.Assertions

  describe "assert_event_recorded/0" do
    test "when the event is found" do
      insert!(:event)

      assert_event_recorded()
    end

    test "when the event is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected an event, got none"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_event_recorded() end
    end
  end

  describe "assert_event_recorded/1" do
    test "when the event is found" do
      %{resource_id: resource_id} = insert!(:event)

      assert_event_recorded(%{resource_id: resource_id})
    end

    test "when the event is not found" do
      message =
        %ExUnit.AssertionError{
          message: "Expected an event with attributes %{resource_id: \"resource_id\"}, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(%{resource_id: "resource_id"})
      end
    end

    test "when data is specified" do
      %{resource_id: resource_id, data: data} = insert!(:event)

      assert_event_recorded(%{
        resource_id: resource_id,
        data: data |> Recase.Enumerable.stringify_keys()
      })
    end

    test "when data is specified but not match" do
      %{data: %{key: "value"}} = insert!(:event)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected an event with attributes %{data: %{\"key\" => \"wrong_value\"}}, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_event_recorded(%{data: %{"key" => "wrong_value"}})
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
        %ExUnit.AssertionError{message: "Expected an outgoing_request, got none"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn -> assert_outgoing_request_recorded() end
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
            "Expected an outgoing_request with attributes %{destination: \"destination\"}, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_outgoing_request_recorded(%{destination: "destination"})
      end
    end
  end
end
