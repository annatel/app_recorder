defmodule AppRecorder.OutgoingRequests.OutgoingRequest do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias AppRecorder.Extensions.Ecto.Types.RequestId

  @type t :: %__MODULE__{
          destination: binary,
          client_error_message: binary | nil,
          id: binary,
          inserted_at: DateTime.t(),
          object: binary,
          requested_at: DateTime.t(),
          request_body: binary | nil,
          request_headers: map,
          request_url: binary,
          responded_at: DateTime.t(),
          response_http_status: integer | nil,
          response_headers: map,
          response_body: binary | nil,
          source: binary,
          success: boolean
        }

  @primary_key {:id, RequestId, prefix: "out_req", autogenerate: false}
  schema "app_recorder_outgoing_requests" do
    field(:destination, :string)
    field(:client_error_message, :string)
    field(:requested_at, :utc_datetime)
    field(:request_body, :string)
    field(:request_headers, :map, default: %{})
    field(:request_method, :string)
    field(:request_url, :string)
    field(:responded_at, :utc_datetime)
    field(:response_http_status, :integer)
    field(:response_headers, :map, default: %{})
    field(:response_body, :string)
    field(:source, :string)
    field(:success, :boolean)

    timestamps()
    field(:object, :string, default: "outgoing_request")
  end

  @spec create_changeset(Request.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = request, attrs) when is_map(attrs) do
    request
    |> cast(attrs, [
      :id,
      :destination,
      :requested_at,
      :request_body,
      :request_headers,
      :request_method,
      :request_url,
      :source
    ])
    |> validate_required([
      :id,
      :destination,
      :requested_at,
      :request_method,
      :request_url,
      :source
    ])
  end

  @spec update_changeset(Request.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = request, attrs) when is_map(attrs) do
    request
    |> cast(attrs, [
      :client_error_message,
      :responded_at,
      :response_http_status,
      :response_headers,
      :response_body,
      :success
    ])
    |> validate_required([:success])
  end
end
