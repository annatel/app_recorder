defmodule AppRecorder.Events.EventSchema do
  defmacro configurable_fields() do
    quote do
      import Ecto.Schema

      if AppRecorder.with_livemode?() do
        field(:livemode, :boolean)
      end

      if AppRecorder.with_sequence?() do
        field(:sequence, :integer)
      end

      field(AppRecorder.owner_id_field_name(), AppRecorder.owner_id_field_type())
    end
  end

  defmacro __using__(_) do
    quote do
      import AppRecorder.Events.EventSchema

      @primary_key if AppRecorder.use_uuid_as_primary_key?(),
                     do: {:id, Shortcode.Ecto.UUID, prefix: "evt", autogenerate: true},
                     else:
                       @primary_key({:id, Shortcode.Ecto.ID, prefix: "evt", autogenerate: true})

      def validate_configurable_event_schema(%Ecto.Changeset{} = changeset, attrs) do
        fields = [AppRecorder.owner_id_field_name()]
        fields = if AppRecorder.with_livemode?(), do: [:livemode | fields], else: fields
        fields = if AppRecorder.with_sequence?(), do: [:sequence | fields], else: fields

        changeset
        |> Ecto.Changeset.cast(attrs, fields)
        |> Ecto.Changeset.validate_required(fields)
      end
    end
  end
end
