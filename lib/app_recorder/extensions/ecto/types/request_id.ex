defmodule AppRecorder.Extensions.Ecto.Types.RequestId do
  use Ecto.ParameterizedType

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
    prefix = Map.get(params, :prefix)

    AppRecorder.RequestId.to_request_id(data, prefix)
  end

  def cast(data, _params) when is_binary(data) and byte_size(data) > 0 do
    {:ok, data}
  end

  def cast(nil, _), do: {:ok, nil}
  def cast(_, _), do: :error

  @impl true
  @spec load(raw() | nil, function, map) :: {:ok, t() | nil} | :error
  def load(<<_::120>> = data, _, params) do
    prefix = Map.get(params, :prefix)

    {:ok, AppRecorder.RequestId.to_request_id!(data, prefix)}
  end

  def load(nil, _, _), do: {:ok, nil}
  def load(_, _, _), do: :error

  @impl true
  @spec dump(t() | raw() | nil, function, map) :: {:ok, raw() | nil} | :error
  def dump(<<_::120>> = data, _, _), do: {:ok, data}

  def dump(data, _, params) when is_binary(data) do
    prefix = Map.get(params, :prefix)

    AppRecorder.RequestId.to_binary(data, prefix)
  end

  def dump(nil, _, _), do: {:ok, nil}
  def dump(_, _, _), do: :error
end
