defmodule AppRecorder.Requests.RelatedResource do
  use AppRecorder.Events.RelatedResourceSchema

  import Ecto.Changeset, only: [cast: 3, unique_constraint: 3, validate_required: 2]

  alias AppRecorder.Extensions.Ecto.Types.RequestId

  @type t :: %__MODULE__{
          resource_id: binary | nil,
          resource_object: binary | nil
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :id, autogenerate: true}
  schema "app_recorder_request_related_resources" do
    configurable_fields()

    field(:request_id, RequestId, prefix: "req")
    field(:resource_id, :string)
    field(:resource_object, :string)

    timestamps(updated_at: false)
  end

  @doc false
  @spec changeset(RelatedResource.t(), map(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = related_resource, attrs, parent_attrs) do
    related_resource
    |> cast(attrs, [:resource_id, :resource_object])
    |> validate_required([:resource_id, :resource_object])
    |> unique_constraint([:request_id, :resource_id, :resource_object, :livemode],
      name: :arrrr_reqid_rid_robject_livemode
    )
    |> cast_and_validate_configurable_fields(attrs, parent_attrs)
  end
end
