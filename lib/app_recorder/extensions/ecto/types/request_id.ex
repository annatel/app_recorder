defmodule AppRecorder.Extensions.Ecto.Types.RequestId do
  use Ecto.ParameterizedType

  @prefix_separator "_"

  @typedoc "A binary string."
  @type t :: binary

  @typedoc "Stored type data"
  @type raw :: <<_::120>>

  @impl true
  @spec init(keyword) :: map
  def init(opts), do: Enum.into(opts, %{})

  @impl true
  @spec type(any) :: :id
  def type(_), do: :id

  @impl true
  @spec cast(raw() | t(), map) :: {:ok, binary} | :error
  def cast(<<_::120>> = data, params) do
    {:ok, data |> Base.url_encode64() |> maybe_add_prefix(Map.get(params, :prefix))}
  end

  def cast(data, params) when is_binary(data) do
    {:ok, data |> maybe_add_prefix(Map.get(params, :prefix))}
  end

  def cast(nil, _), do: {:ok, nil}
  def cast(_, _), do: :error

  @impl true
  @spec load(raw() | nil, function, map) :: {:ok, t() | nil} | :error
  def load(<<_::120>> = data, _, params) do
    {:ok, data |> Base.url_encode64() |> maybe_add_prefix(Map.get(params, :prefix))}
  end

  def load(nil, _, _), do: {:ok, nil}
  def load(_, _, _), do: :error

  @impl true
  @spec dump(t() | raw() | nil, function, map) :: {:ok, raw() | nil} | :error
  def dump(<<_::120>> = data, _, _), do: {:ok, data}

  def dump(data, _, params) when is_binary(data) do
    {:ok, data |> maybe_remove_prefix(Map.get(params, :prefix)) |> Base.url_decode64!()}
  end

  def dump(nil, _, _), do: {:ok, nil}
  def dump(_, _, _), do: :error

  defp maybe_add_prefix(data, nil), do: data
  defp maybe_add_prefix(data, prefix), do: "#{prefix}#{@prefix_separator}#{data}"

  defp maybe_remove_prefix(data, nil), do: data

  defp maybe_remove_prefix(data, prefix),
    do: data |> String.split("#{prefix}#{@prefix_separator}") |> List.last()
end
