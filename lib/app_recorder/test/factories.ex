defmodule AppRecorder.Test.Factories do
  @moduledoc false

  alias AppRecorder.Events.Event

  @spec build(:event, Enum.t()) :: struct
  def build(:event, attrs) do
    %Event{
      api_version: "api_version",
      created_at: utc_now(),
      data: %{key: "value"},
      idempotency_key: "idempotency_key_#{System.unique_integer()}",
      request_id: AppRecorder.RequestId.generate_request_id("req"),
      request_idempotency_key: "request_idempotency_key_#{System.unique_integer()}",
      resource_id: "resource_id_#{System.unique_integer()}",
      resource_object: "resource_object_#{System.unique_integer()}",
      type: "type_#{System.unique_integer()}"
    }
    |> put_owner_id()
    |> maybe_put_livemode()
    |> maybe_put_sequence()
    |> struct!(attrs)
  end

  defp put_owner_id(%Event{} = event) do
    owner_id_value =
      if elem(AppRecorder.owner_id_field(:schema), 1) == :binary_id,
        do: Ecto.UUID.generate(),
        else: System.unique_integer([:positive])

    event |> Map.put(elem(AppRecorder.owner_id_field(:schema), 0), owner_id_value)
  end

  defp maybe_put_sequence(%Event{} = event) do
    attrs =
      if AppRecorder.with_sequence?(),
        do: %{sequence: System.unique_integer([:positive])},
        else: %{}

    event |> Map.merge(attrs)
  end

  defp maybe_put_livemode(%Event{} = event) do
    attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

    event |> Map.merge(attrs)
  end

  @spec params_for(struct) :: map
  def params_for(schema) when is_struct(schema) do
    schema
    |> AntlUtilsEcto.map_from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @spec params_for(atom, Enum.t()) :: map
  def params_for(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> params_for()
  end

  @spec build(atom) :: %{:__struct__ => atom, optional(atom) => any}
  def build(factory_name), do: build(factory_name, [])

  @spec insert!(atom, Enum.t()) :: any
  def insert!(factory_name, attributes)
      when is_atom(factory_name) or is_tuple(factory_name) do
    factory_name |> build(attributes) |> insert!()
  end

  @spec insert!(atom | tuple | struct) :: struct
  def insert!(factory_name) when is_atom(factory_name) or is_tuple(factory_name) do
    factory_name |> build([]) |> insert!()
  end

  def insert!(schema) when is_struct(schema), do: schema |> AppRecorder.repo().insert!()

  defp utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)
end