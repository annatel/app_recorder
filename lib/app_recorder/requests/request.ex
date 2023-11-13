defmodule AppRecorder.Requests.Request do
  use AppRecorder.Requests.RequestSchema

  import Ecto.Changeset, only: [cast: 3, cast_assoc: 3, get_field: 2, validate_required: 2]

  alias AppRecorder.Extensions.Ecto.Types.RequestId
  alias AppRecorder.Requests.RelatedResource

  @type t :: %__MODULE__{
          created_at: DateTime.t(),
          id: binary,
          idempotency_key: binary,
          inserted_at: DateTime.t(),
          object: binary,
          related_resources: [RelatedResource.t()],
          request_data: map,
          response_data: map,
          source: boolean,
          success: boolean,
          updated_at: DateTime.t()
        }

  @primary_key {:id, RequestId, prefix: "req", autogenerate: false}
  schema "app_recorder_requests" do
    configurable_fields()

    field(:created_at, :utc_datetime)
    field(:idempotency_key, :string)
    has_many(:related_resources, RelatedResource, preload_order: [asc: :id])
    field(:request_data, :map, default: %{})
    field(:response_data, :map, default: %{})
    field(:source, :string)
    field(:success, :boolean)

    timestamps()
    field(:object, :string, default: "request")
  end

  @spec create_changeset(Request.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = request, attrs) when is_map(attrs) do
    request
    |> cast(attrs, [
      :id,
      :created_at,
      :idempotency_key,
      :request_data,
      :response_data,
      :source,
      :success
    ])
    |> validate_required([:id, :created_at, :request_data])
    |> validate_configurable_fields(attrs)
    |> cast_assoc_related_resources()
  end

  @spec update_changeset(Request.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = request, attrs) when is_map(attrs) do
    request
    |> cast(attrs, [:response_data, :success])
  end

  defp cast_assoc_related_resources(%Ecto.Changeset{} = changeset) do
    changeset
    |> cast_assoc(:related_resources,
      required: false,
      with: fn cset, attrs ->
        RelatedResource.changeset(cset, attrs, %{livemode: get_field(changeset, :livemode)})
      end
    )
  end
end
