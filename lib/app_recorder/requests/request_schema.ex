defmodule AppRecorder.Requests.RequestSchema do
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
    end
  end

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import AppRecorder.Requests.RequestSchema

      defp validate_configurable_fields(%Ecto.Changeset{} = changeset, attrs) do
        fields = [elem(AppRecorder.owner_id_field(), 0)]
        fields = if AppRecorder.with_livemode?(), do: [:livemode | fields], else: fields

        changeset
        |> Ecto.Changeset.cast(attrs, fields)
        |> Ecto.Changeset.validate_required(fields)
      end
    end
  end
end
