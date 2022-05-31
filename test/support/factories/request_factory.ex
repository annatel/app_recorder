defmodule AppRecorder.Factory.Request do
  alias AppRecorder.Requests.Request
  alias AppRecorder.Requests.RelatedResource

  defmacro __using__(_opts) do
    quote do
      def build(:request, attrs) do
        %Request{
          created_at: utc_now(),
          id: request_id("req"),
          idempotency_key: "idempotency_key_#{System.unique_integer()}",
          related_resources: [build(:request_related_resource)],
          request_data: %{key: "value"},
          response_data: %{key: "value"},
          source: "source_#{System.unique_integer()}",
          success: true
        }
        |> put_owner_id()
        |> maybe_put_livemode()
        |> struct!(attrs)
      end

      def build(:request_related_resource, attrs) do
        %RelatedResource{
          resource_id: "resource_id_#{System.unique_integer()}",
          resource_object: "resource_object_#{System.unique_integer()}"
        }
        |> maybe_put_livemode()
        |> struct!(attrs)
      end

      defp put_owner_id(%Request{} = request) do
        owner_id_value =
          if elem(AppRecorder.owner_id_field(:schema), 1) == :binary_id,
            do: uuid(),
            else: id()

        request |> Map.put(elem(AppRecorder.owner_id_field(:schema), 0), owner_id_value)
      end

      defp maybe_put_livemode(%Request{} = request) do
        attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

        request |> Map.merge(attrs)
      end

      defp maybe_put_livemode(%RelatedResource{} = related_resource) do
        attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

        related_resource |> Map.merge(attrs)
      end
    end
  end
end
