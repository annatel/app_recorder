defmodule AppRecorder.OutgoingRequests.OutgoingRequestTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.OutgoingRequests.OutgoingRequest

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      outgoing_request_params = params_for(:outgoing_request, request_headers: %{key: "value"})

      changeset = OutgoingRequest.create_changeset(%OutgoingRequest{}, outgoing_request_params)

      changes_keys = changeset.changes |> Map.keys()

      assert :id in changes_keys
      assert :destination in changes_keys
      refute :client_error_message in changes_keys
      assert :requested_at in changes_keys
      assert :request_body in changes_keys
      assert :request_headers in changes_keys
      assert :request_method in changes_keys
      assert :request_url in changes_keys
      refute :responded_at in changes_keys
      refute :response_http_status in changes_keys
      refute :response_headers in changes_keys
      refute :response_body in changes_keys
      assert :source in changes_keys
      refute :success in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      outgoing_request_params = params_for(:outgoing_request, request_headers: %{key: "value"})

      changeset = OutgoingRequest.create_changeset(%OutgoingRequest{}, outgoing_request_params)

      assert changeset.valid?

      assert get_field(changeset, :id) == outgoing_request_params.id
      assert get_field(changeset, :destination) == outgoing_request_params.destination
      assert get_field(changeset, :requested_at) == outgoing_request_params.requested_at
      assert get_field(changeset, :request_body) == outgoing_request_params.request_body
      assert get_field(changeset, :request_headers) == outgoing_request_params.request_headers
      assert get_field(changeset, :request_method) == outgoing_request_params.request_method
      assert get_field(changeset, :request_url) == outgoing_request_params.request_url
      assert get_field(changeset, :source) == outgoing_request_params.source
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = OutgoingRequest.create_changeset(%OutgoingRequest{}, %{})

      refute changeset.valid?
      assert length(changeset.errors) == 6
      assert %{id: ["can't be blank"]} = errors_on(changeset)
      assert %{destination: ["can't be blank"]} = errors_on(changeset)
      assert %{requested_at: ["can't be blank"]} = errors_on(changeset)
      assert %{request_method: ["can't be blank"]} = errors_on(changeset)
      assert %{request_url: ["can't be blank"]} = errors_on(changeset)
      assert %{source: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
