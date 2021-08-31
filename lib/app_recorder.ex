defmodule AppRecorder do
  @moduledoc false

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:app_recorder, :repo)
  end

  @doc false
  @spec primary_key_type :: atom
  def primary_key_type() do
    Application.get_env(:app_recorder, :primary_key_type, :id)
  end

  @doc false
  @spec owner_id_field(atom) :: tuple
  def owner_id_field(:migration) do
    Application.get_env(:app_recorder, :owner_id_field, migration: {:owner_id, :binary_id})[
      :migration
    ]
  end

  def owner_id_field(:schema) do
    Application.get_env(:app_recorder, :owner_id_field, schema: {:owner_id, :binary_id, []})[
      :schema
    ]
  end

  @doc false
  @spec with_livemode? :: boolean
  def with_livemode?() do
    Application.get_env(:app_recorder, :with_livemode?, true)
  end

  @doc false
  @spec with_path? :: boolean
  def with_path?() do
    Application.get_env(:app_recorder, :with_path?, false)
  end

  @doc false
  @spec with_sequence? :: boolean
  def with_sequence?() do
    Application.get_env(:app_recorder, :with_sequence?, false)
  end
end
