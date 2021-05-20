defmodule AppRecorder.Events.Event do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  @type t :: %__MODULE__{
          created_at: DateTime.t(),
          data: map,
          id: binary,
          inserted_at: DateTime.t(),
          livemode: boolean,
          owner_id: binary,
          request_id: binary | nil,
          resource_id: binary | nil,
          resource_object: binary | nil,
          sequence: integer,
          type: binary
        }

  @primary_key {:id, Shortcode.Ecto.UUID, prefix: "evt", autogenerate: true}
  schema "app_recorder_events" do
    field(:created_at, :utc_datetime)
    field(:data, :map, default: %{})
    field(:livemode, :boolean, default: true)
    field(:owner_id, :string)
    field(:request_id, :string)
    field(:resource_id, :string)
    field(:resource_object, :string)
    field(:sequence, :integer)
    field(:type, :string)

    timestamps(updated_at: false)
    field(:object, :string, default: "event")
  end

  @doc false
  @spec changeset(Event.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = event, attrs) do
    event
    |> cast(attrs, [
      :created_at,
      :data,
      :livemode,
      :owner_id,
      :request_id,
      :resource_id,
      :resource_object,
      :sequence,
      :type
    ])
    |> validate_required([:created_at, :data, :livemode, :owner_id, :sequence, :type])
  end
end
