defmodule AppRecorder.Events.Event do
  use AppRecorder.Events.EventSchema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias AppRecorder.Extensions.Ecto.Types.RequestId

  @type t :: %__MODULE__{
          api_version: binary,
          created_at: DateTime.t(),
          data: map,
          idempotency_key: binary | nil,
          inserted_at: DateTime.t(),
          object: binary,
          request_id: binary | nil,
          resource_id: binary | nil,
          resource_object: binary | nil,
          type: binary
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "app_recorder_events" do
    configurable_fields()

    field(:api_version, :string, default: "2021-01-01")
    field(:created_at, :utc_datetime)
    field(:data, :map, default: %{})
    field(:idempotency_key, :string)
    field(:request_id, RequestId, prefix: "req")
    field(:resource_id, :string)
    field(:resource_object, :string)
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
      :idempotency_key,
      :request_id,
      :resource_id,
      :resource_object,
      :type
    ])
    |> validate_required([:created_at, :data, :type])
    |> validate_configurable_fields(attrs)
  end
end
