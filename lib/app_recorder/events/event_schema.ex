defmodule AppRecorder.Events.EventSchema do
  defmacro configurable_fields() do
    quote do
      import Ecto.Schema

      field(
        elem(AppRecorder.owner_id_field(), 0),
        elem(AppRecorder.owner_id_field(), 1),
        elem(AppRecorder.owner_id_field(), 2)
      )

      if AppRecorder.with_livemode?() do
        field(:livemode, :boolean)
      end

      if AppRecorder.with_sequence?() do
        field(:sequence, :integer)
      end
    end
  end

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import AppRecorder.Events.EventSchema

      @primary_key_type AppRecorder.primary_key_type()
      @shortcode_types %{id: Shortcode.Ecto.ID, binary_id: Shortcode.Ecto.UUID}

      @primary_key {:id, @shortcode_types[@primary_key_type], prefix: "evt", autogenerate: true}

      defp validate_configurable_fields(%Ecto.Changeset{} = changeset, attrs) do
        fields = [elem(AppRecorder.owner_id_field(), 0)]
        fields = if AppRecorder.with_livemode?(), do: [:livemode | fields], else: fields
        fields = if AppRecorder.with_sequence?(), do: [:sequence | fields], else: fields

        changeset
        |> Ecto.Changeset.cast(attrs, fields)
        |> Ecto.Changeset.validate_required(fields)
      end
    end
  end
end
