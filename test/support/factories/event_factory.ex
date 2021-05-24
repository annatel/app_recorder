defmodule AppRecorder.Factory.Event do
  alias AppRecorder.Events.Event

  defmacro __using__(_opts) do
    quote do
      def build(:event, attrs) do
        %Event{
          created_at: utc_now(),
          data: %{key: "value"},
          owner_id: uuid(),
          request_id: "request_id_#{System.unique_integer([:positive])}",
          resource_id: "resource_id_#{System.unique_integer()}",
          resource_object: "resource_object_#{System.unique_integer()}",
          sequence: System.unique_integer([:positive]),
          type: "type_#{System.unique_integer()}"
        }
        |> struct!(attrs)
      end
    end
  end
end
