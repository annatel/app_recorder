defmodule AppRecorder.Factory.Event do
  alias AppRecorder.Events.Event
  alias AppRecorder.Events.RelatedResource

  defmacro __using__(_opts) do
    quote do
      def build(:event, attrs) do
        %Event{
          api_version: "api_version",
          created_at: utc_now(),
          data: %{key: "value"},
          idempotency_key: "idempotency_key_#{System.unique_integer()}",
          origin: "origin_#{System.unique_integer()}",
          related_resources: [build(:event_related_resource)],
          request_id: request_id("req"),
          request_idempotency_key: "request_idempotency_key_#{System.unique_integer()}",
          resource_id: "resource_id_#{System.unique_integer()}",
          resource_object: "resource_object_#{System.unique_integer()}",
          source: "source_#{System.unique_integer()}",
          source_event_id: shortcode_uuid("evt"),
          type: "type_#{System.unique_integer()}"
        }
        |> put_owner_id()
        |> maybe_put_livemode()
        |> maybe_put_ref()
        |> maybe_put_sequence()
        |> struct!(attrs)
      end

      def build(:event_related_resource, attrs) do
        %RelatedResource{
          resource_id: "resource_id_#{System.unique_integer()}",
          resource_object: "resource_object_#{System.unique_integer()}"
        }
        |> maybe_put_livemode()
        |> struct!(attrs)
      end

      defp put_owner_id(%Event{} = event) do
        owner_id_value =
          if elem(AppRecorder.owner_id_field(:schema), 1) == :binary_id,
            do: uuid(),
            else: id()

        event |> Map.put(elem(AppRecorder.owner_id_field(:schema), 0), owner_id_value)
      end

      defp maybe_put_ref(%Event{} = event) do
        attrs =
          if AppRecorder.with_ref?(),
            do: %{ref: "ref_#{System.unique_integer()}"},
            else: %{}

        event |> Map.merge(attrs)
      end

      defp maybe_put_sequence(%Event{} = event) do
        attrs =
          if AppRecorder.with_sequence?(),
            do: %{sequence: AppRecorder.Sequences.next_value!(:events)},
            else: %{}

        event |> Map.merge(attrs)
      end

      defp maybe_put_livemode(%Event{} = event) do
        attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

        event |> Map.merge(attrs)
      end

      defp maybe_put_livemode(%RelatedResource{} = related_resource) do
        attrs = if AppRecorder.with_livemode?(), do: %{livemode: false}, else: %{}

        related_resource |> Map.merge(attrs)
      end
    end
  end
end
