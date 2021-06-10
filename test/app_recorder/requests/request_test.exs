defmodule AppRecorder.Requests.RequestTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.Requests.Request

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      request_params = params_for(:request)

      changeset =
        Request.create_changeset(
          %Request{},
          Map.merge(request_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :created_at in changes_keys
      assert :idempotency_key in changes_keys
      assert :livemode in changes_keys
      assert :owner_id in changes_keys
      assert :request_data in changes_keys
      assert :response_data in changes_keys
      assert :source in changes_keys
      assert :success in changes_keys
      refute :new_key in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      request_params = params_for(:request)

      changeset = Request.create_changeset(%Request{}, request_params)

      assert changeset.valid?

      assert get_field(changeset, :created_at) == request_params.created_at
      assert get_field(changeset, :idempotency_key) == request_params.idempotency_key
      assert get_field(changeset, :livemode) == request_params.livemode
      assert get_field(changeset, :owner_id) == request_params.owner_id
      assert get_field(changeset, :request_data) == request_params.request_data
      assert get_field(changeset, :response_data) == request_params.response_data
      assert get_field(changeset, :source) == request_params.source
      assert get_field(changeset, :success) == request_params.success
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = Request.create_changeset(%Request{}, %{request_data: nil, response_data: nil})

      refute changeset.valid?
      assert %{created_at: ["can't be blank"]} = errors_on(changeset)
      assert %{livemode: ["can't be blank"]} = errors_on(changeset)
      assert %{request_data: ["can't be blank"]} = errors_on(changeset)
      assert %{owner_id: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
