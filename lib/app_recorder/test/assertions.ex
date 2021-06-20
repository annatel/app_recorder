defmodule AppRecorder.Test.Assertions do
  import ExUnit.Assertions

  alias AppRecorder.Events
  alias AppRecorder.OutgoingRequests

  @doc """
  Asserts an event is created

  It can be used as below:

  # Examples:

      assert_event_recorded()
      assert_event_recorded(%{resource_id: "id")
  """
  @spec assert_event_recorded(map) :: true
  def assert_event_recorded(attrs \\ %{})

  def assert_event_recorded(%{data: data} = attrs) do
    events = Events.list_events(filter: attrs |> Map.delete(:data) |> Enum.to_list())

    assert length(events) != 0, message("event", attrs)

    assert Enum.filter(events, fn event -> subset?(data, event.data) end) != [],
           message("event", attrs)
  end

  def assert_event_recorded(attrs) do
    events = Events.list_events(filter: attrs |> Enum.to_list())

    assert length(events) != 0, message("event", attrs)
  end

  @doc """
  Asserts an outgoing_request is created

  It can be used as below:

  # Examples:

      assert_outgoing_request_recorded()
      assert_outgoing_request_recorded(%{destination: "destination")
  """
  @spec assert_outgoing_request_recorded(map) :: true
  def assert_outgoing_request_recorded(attrs \\ %{})

  def assert_outgoing_request_recorded(attrs) do
    outgoing_requests = OutgoingRequests.list_outgoing_requests(filter: attrs |> Enum.to_list())

    assert length(outgoing_requests) != 0, message("outgoing_request", attrs)
  end

  defp subset?(a, b) do
    MapSet.subset?(a |> MapSet.new(), b |> MapSet.new())
  end

  defp message(resource_name, %{} = attrs) do
    if Enum.empty?(attrs),
      do: "Expected an #{resource_name}, got none",
      else: "Expected an #{resource_name} with attributes #{inspect(attrs)}, got none"
  end
end
