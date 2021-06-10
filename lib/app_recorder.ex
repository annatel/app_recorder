defmodule AppRecorder do
  @moduledoc false

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:app_recorder, :repo)
  end

  @doc false
  @spec primary_key_type :: boolean
  def primary_key_type() do
    Application.get_env(:app_recorder, :primary_key_type, :id)
  end

  @doc false
  @spec owner_id_field :: tuple
  def owner_id_field() do
    Application.get_env(:app_recorder, :owner_id_field, {:owner_id, :string, []})
  end

  @doc false
  @spec with_livemode? :: boolean
  def with_livemode?() do
    Application.get_env(:app_recorder, :with_livemode?, true)
  end

  @doc false
  @spec with_sequence? :: boolean
  def with_sequence?() do
    Application.get_env(:app_recorder, :with_sequence?, false)
  end
end
