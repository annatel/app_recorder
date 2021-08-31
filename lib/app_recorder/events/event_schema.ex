defmodule AppRecorder.Events.EventSchema do
  defmacro configurable_fields() do
    quote do
      import Ecto.Schema

      field(
        elem(AppRecorder.owner_id_field(:schema), 0),
        elem(AppRecorder.owner_id_field(:schema), 1),
        elem(AppRecorder.owner_id_field(:schema), 2)
      )

      if AppRecorder.with_livemode?() do
        field(:livemode, :boolean)
      end

      if AppRecorder.with_path?() do
        field(:path, :string)
      end

      if AppRecorder.with_sequence?() do
        field(:sequence, :integer)
      end

      field(:source_event_id, elem(@primary_key, 1), prefix: "evt")
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
        required_fields = [elem(AppRecorder.owner_id_field(:schema), 0)]

        required_fields =
          if AppRecorder.with_livemode?(),
            do: [:livemode | required_fields],
            else: required_fields

        required_fields =
          if AppRecorder.with_sequence?(),
            do: [:sequence | required_fields],
            else: required_fields

        required_fields =
          if AppRecorder.with_path?(),
            do: [:path | required_fields],
            else: required_fields

        changeset
        |> Ecto.Changeset.cast(attrs, required_fields ++ [:source_event_id])
        |> Ecto.Changeset.validate_required(required_fields)
      end
    end
  end
end
