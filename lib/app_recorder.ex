defmodule AppRecorder do
  @moduledoc """
  AppRecorder
  """

  @behaviour AppRecorder.Behaviour

  alias AppRecorder.Events

  @doc ~S"""
  List all events
  """
  @spec list_events(keyword) :: %{data: [Event.t()], total: integer}
  defdelegate list_events(opts \\ []), to: Events

  @doc ~S"""
  Returns an event struct with pre-filled fields.
  """
  @spec new_event!(%{:owner_id => binary, optional(atom) => any}) :: Event.t()
  defdelegate new_event!(fields), to: Events

  @doc ~S"""
  Record an event

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event!(Event.t(), binary, map, keyword) :: Event.t()
  defdelegate record_event!(event_schema, type, data, opts \\ []), to: Events

  @doc ~S"""
  Return an record event multi

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event_multi(Ecto.Multi.t(), Event.t(), binary, map | function, keyword) ::
          Ecto.Multi.t()
  defdelegate record_event_multi(multi, event_schema, type, mixed, opts \\ []), to: Events

  @doc ~S"""
  Get an event
  """
  @spec get_event(binary) :: Event.t()
  defdelegate get_event(id), to: Events

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:app_recorder, :repo)
  end
end
