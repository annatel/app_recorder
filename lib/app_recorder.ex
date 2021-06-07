defmodule AppRecorder do
  @moduledoc """
  AppRecorder
  """

  alias AppRecorder.Events

  @doc ~S"""
  List all events
  """
  @spec list_events(keyword) :: %{data: [Event.t()], total: integer}
  defdelegate list_events(opts \\ []), to: Events

  @doc ~S"""
  Record an event

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event!(map, keyword) :: Event.t()
  defdelegate record_event!(attrs, opts \\ []), to: Events

  @doc ~S"""
  Return an record event multi

  ## Options

    * `:allowed_event_types` - List of allowed event types

  """
  @spec record_event_multi(Ecto.Multi.t(), map | function, keyword) :: Ecto.Multi.t()
  defdelegate record_event_multi(multi, mixed, opts \\ []), to: Events

  @doc ~S"""
  Get an event
  """
  @spec get_event(binary) :: Event.t() | nil
  defdelegate get_event(id), to: Events

  @spec get_event!(binary) :: Event.t()
  defdelegate get_event!(id), to: Events

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:app_recorder, :repo)
  end

  @doc false
  @spec use_uuid_as_primary_key? :: boolean
  def use_uuid_as_primary_key?() do
    Application.get_env(:app_recorder, :use_uuid_as_primary_key?, false)
  end

  @doc false
  @spec with_sequence? :: boolean
  def with_sequence?() do
    Application.get_env(:app_recorder, :with_sequence?, false)
  end

  @doc false
  @spec with_livemode? :: boolean
  def with_livemode?() do
    Application.get_env(:app_recorder, :with_livemode, true)
  end

  @doc false
  @spec owner_id_field_name :: atom
  def owner_id_field_name() do
    Application.get_env(:app_recorder, :owner_id_field_name, :owner_id)
  end

  @doc false
  @spec owner_id_field_type :: atom
  def owner_id_field_type() do
    Application.get_env(:app_recorder, :owner_id_field_type, :string)
  end
end
