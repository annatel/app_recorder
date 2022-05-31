defmodule AppRecorder.Test.Assertions do
  import ExUnit.Assertions

  alias AppRecorder.Events
  alias AppRecorder.Requests
  alias AppRecorder.OutgoingRequests

  @doc """
  Asserts an event is created

  It can be used as below:

  # Examples:

      assert_event_recorded()
      assert_event_recorded(%{resource_id: "id")
  """
  @spec assert_event_recorded(map | pos_integer | nil) :: true
  def assert_event_recorded(attrs \\ %{})

  def assert_event_recorded(%{} = attrs), do: assert_event_recorded(1, attrs)

  def assert_event_recorded(expected_count) when is_integer(expected_count),
    do: assert_event_recorded(expected_count, %{})

  @spec assert_event_recorded(integer, map) :: true
  def assert_event_recorded(expected_count, %{data: data} = attrs)
      when is_integer(expected_count) do
    events = Events.list_events(filters: attrs |> Map.delete(:data) |> Enum.to_list())

    count = events |> Enum.filter(fn event -> subset?(data, event.data) end) |> length()

    assert count == expected_count, message("event", attrs, expected_count, count)
  end

  def assert_event_recorded(expected_count, attrs) when is_integer(expected_count) do
    events = Events.list_events(filters: attrs |> Enum.to_list())
    count = length(events)

    assert count == expected_count, message("event", attrs, expected_count, count)
  end

  @doc """
  Asserts an request is created

  It can be used as below:

  # Examples:

      assert_request_recorded()
      assert_request_recorded(%{idempotency_key: "idempotency_key")
  """
  @spec assert_request_recorded(map | pos_integer | nil) :: true
  def assert_request_recorded(attrs \\ %{})

  def assert_request_recorded(%{} = attrs), do: assert_request_recorded(1, attrs)

  def assert_request_recorded(expected_count) when is_integer(expected_count),
    do: assert_request_recorded(expected_count, %{})

  @spec assert_request_recorded(integer, map) :: true
  def assert_request_recorded(
        expected_count,
        attrs
      )
      when is_integer(expected_count) do
    requests =
      Requests.list_requests(
        filters: attrs |> Map.drop([:request_data, :response_data]) |> Enum.to_list()
      )

    request_data = Map.get(attrs, :request_data, %{})
    response_data = Map.get(attrs, :response_data, %{})

    count =
      requests
      |> Enum.filter(fn request -> subset?(request_data, request.request_data) end)
      |> Enum.filter(fn request -> subset?(response_data, request.response_data) end)
      |> length()

    assert count == expected_count, message("request", attrs, expected_count, count)
  end

  def assert_request_recorded(expected_count, attrs) when is_integer(expected_count) do
    requests = Requests.list_requests(filters: attrs |> Enum.to_list())
    count = length(requests)

    assert count == expected_count, message("request", attrs, expected_count, count)
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

  def assert_outgoing_request_recorded(%{} = attrs),
    do: assert_outgoing_request_recorded(1, attrs)

  def assert_outgoing_request_recorded(expected_count) when is_integer(expected_count),
    do: assert_outgoing_request_recorded(expected_count, %{})

  def assert_outgoing_request_recorded(expected_count, attrs) do
    outgoing_requests = OutgoingRequests.list_outgoing_requests(filters: attrs |> Enum.to_list())

    count = length(outgoing_requests)
    assert count == expected_count, message("outgoing_request", attrs, expected_count, count)
  end

  defp subset?(a, b) do
    MapSet.subset?(a |> MapSet.new(), b |> MapSet.new())
  end

  defp message(resource_name, %{} = attrs, expected_count, count) do
    if Enum.empty?(attrs),
      do:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)}, got #{count}",
      else:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)} with attributes #{inspect(attrs)}, got #{count}"
  end

  defp maybe_pluralized_item(resource_name, count) when count > 1, do: resource_name <> "s"
  defp maybe_pluralized_item(resource_name, _), do: resource_name
end
