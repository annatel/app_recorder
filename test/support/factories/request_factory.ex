defmodule AppRecorder.Factory.Request do
  alias AppRecorder.Requests.Request

  defmacro __using__(_opts) do
    quote do
      def build(:request, attrs) do
        %Request{
          created_at: utc_now(),
          id: request_id(),
          idempotency_key: "idempotency_key_#{System.unique_integer()}",
          request_data: %{key: "value"},
          response_data: %{key: "value"},
          source: "source_#{System.unique_integer()}",
          success: true
        }
        |> put_owner_id()
        |> maybe_put_livemode()
        |> struct!(attrs)
      end

      defp put_owner_id(%Request{} = request) do
        owner_id_value =
          if elem(AppRecorder.owner_id_field(), 1) == :binary_id,
            do: uuid(),
            else: id()

        request |> Map.put(elem(AppRecorder.owner_id_field(), 0), owner_id_value)
      end

      defp maybe_put_livemode(%Request{} = request) do
        attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

        request |> Map.merge(attrs)
      end
    end
  end
end
