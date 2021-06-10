defmodule AppRecorder.RequestId do
  @moduledoc false
  @prefix_separator "_"

  @doc """
  Convert an binary to a request_id with support of prefix.

  ## Examples

      iex> RequestId.to_request_id(<<0::120>>, "prefix")
      {:ok, "prefix_aaaaaaaaaaaaaaaaaaaaaaaa"}

      iex> RequestId.to_request_id(<<0::120>>)
      {:ok, "aaaaaaaaaaaaaaaaaaaaaaaa"}

      iex> RequestId.to_request_id("request_id")
      :error

      iex> RequestId.to_request_id(1)
      :error

  """
  @spec to_request_id(binary, binary | nil) :: {:ok, binary} | :error
  def to_request_id(data, prefix \\ nil)

  def to_request_id(<<_::120>> = binary, prefix) do
    request_id = binary |> Base.encode32(case: :lower, padding: false)

    request_id = if prefix, do: "#{prefix}#{@prefix_separator}#{request_id}", else: request_id

    {:ok, request_id}
  end

  def to_request_id(_, _), do: :error

  @spec to_request_id!(binary, binary | nil) :: binary
  def to_request_id!(data, prefix \\ nil) do
    case to_request_id(data, prefix) do
      {:ok, request_id} -> request_id
      :error -> raise ArgumentError, "cannot convert #{inspect(data)} to request_id"
    end
  end

  @doc """
  Convert a request_id to a binary.

  ## Examples

      iex> RequestId.to_binary("aaaaaaaaaaaaaaaaaaaaaaaa")
      {:ok, <<0::120>>}

      iex> RequestId.to_binary("prefix_aaaaaaaaaaaaaaaaaaaaaaaa", "prefix")
      {:ok, <<0::120>>}

      iex> RequestId.to_binary("foo_aaaaaaaaaaaaaaaaaaaaaaaa", "bar")
      :error

      iex> RequestId.to_binary(1)
      :error

      iex> RequestId.to_binary(<<0::120>>)
      :error

      iex> RequestId.to_binary(nil)
      :error

  """

  @spec to_binary(binary, binary | nil) :: {:ok, binary} | :error
  def to_binary(request_id, prefix \\ nil)

  def to_binary(request_id, nil) when is_binary(request_id) do
    Base.decode32(request_id, case: :lower, padding: false)
  end

  def to_binary(request_id, prefix) when is_binary(request_id) do
    request_id
    |> String.split(@prefix_separator, parts: 2)
    |> case do
      [^prefix, data] -> to_binary(data, nil)
      _ -> :error
    end
  end

  def to_binary(_, _), do: :error

  @spec generate_request_id(binary | nil) :: binary
  def generate_request_id(prefix \\ nil) do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    to_request_id!(binary, prefix)
  end
end
