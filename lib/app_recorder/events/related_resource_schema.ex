defmodule AppRecorder.Events.RelatedResourceSchema do
  defmacro configurable_fields() do
    quote do
      import Ecto.Schema

      if AppRecorder.with_livemode?() do
        field(:livemode, :boolean)
      end

      field(:event_id, @shortcode_types[@primary_key_type], prefix: "evt")
    end
  end

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import AppRecorder.Events.RelatedResourceSchema

      @primary_key_type AppRecorder.primary_key_type()
      @shortcode_types %{id: Shortcode.Ecto.ID, binary_id: Shortcode.Ecto.UUID}

      defp cast_and_validate_configurable_fields(
             %Ecto.Changeset{} = changeset,
             attrs,
             parent_attrs
           ) do
        if AppRecorder.with_livemode?(),
          do: changeset |> Ecto.Changeset.put_change(:livemode, Map.get(parent_attrs, :livemode)),
          else: changeset
      end
    end
  end
end
