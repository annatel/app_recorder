defmodule AppRecorder.Test.Assertions do
  import ExUnit.Assertions

  alias AppRecorder.Events

  @doc """
  Asserts the event is created

  It can be used as below:

  # Examples:

      assert_event_recorded()
      assert_event_recorded(%{resource_id: "id")
  """

  def assert_event_recorded(attrs \\ %{})

  def assert_event_recorded(%{data: %{} = data} = attrs) do
    %{total: total, data: events} =
      Events.list_events(filter: attrs |> Map.delete(:data) |> Enum.to_list())

    assert total != 0, message(attrs)

    assert Enum.filter(events, fn event ->
             subset?(data, event.data |> Recase.Enumerable.atomize_keys())
           end) != [],
           message(attrs)
  end

  def assert_event_recorded(attrs) do
    %{total: total} = Events.list_events(filter: attrs |> Enum.to_list())

    assert total != 0, message(attrs)
  end

  defp subset?(a, b) do
    MapSet.subset?(a |> MapSet.new(), b |> MapSet.new())
  end

  defp message(%{} = attrs) do
    if Enum.empty?(attrs),
      do: "Expected an event, got none",
      else: "Expected an event with attributes #{inspect(attrs)}, got none"
  end
end
