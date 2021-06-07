defmodule AppRecorder.Test.Assertions do
  import ExUnit.Assertions

  @doc """
  Asserts the event is created

  It can be used as below:

  # Examples:

      assert_event_recorded()
      assert_event_recorded(%{resource_id: "id")
  """
  def assert_event_recorded(attrs \\ %{}) do
    %{total: total, data: _} = AppRecorder.list_events(filters: attrs |> Enum.to_list())

    message =
      if Enum.empty?(attrs) do
        "Expected an event, got none"
      else
        "Expected an event with attributes #{inspect(attrs)}, got none"
      end

    assert total != 0, message
  end
end
