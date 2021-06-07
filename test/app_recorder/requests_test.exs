defmodule AppRecorder.RequestsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.TestRepo

  alias AppRecorder.Requests
  alias AppRecorder.Requests.Request

  describe "list_requests/1" do
    test "returns the list of requests ordered by the id descending" do
      %{id: id_1} = insert!(:request) |> IO.inspect()

      assert %{data: [%Request{id: ^id_1}], total: 1} = Requests.list_requests()
    end

    # test "order_by" do
    #   %{id: id1} = insert!(:request)
    #   %{id: id2} = insert!(:request)

    #   assert %{data: [%{id: ^id2}, %{id: ^id1}]} = Requests.list_requests()

    #   assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
    #            Requests.list_requests(order_by_fields: [asc: :id])
    # end

    # test "filters" do
    #   request = insert!(:request)

    #   [
    #     [id: request.id],
    #     [idempotency_key: request.idempotency_key],
    #     [livemode: request.livemode],
    #     [owner_id: request.owner_id],
    #     [source: request.source],
    #     [success: request.success]
    #   ]
    #   |> Enum.each(fn filter ->
    #     assert %{data: [_request], total: 1} = Requests.list_requests(filters: filter)
    #   end)

    #   [
    #     [id: request_id("req")],
    #     [idempotency_key: "idempotency_key"],
    #     [livemode: !request.livemode],
    #     [owner_id: uuid()],
    #     [source: "source"],
    #     [success: !request.success]
    #   ]
    #   |> Enum.each(fn filter ->
    #     assert %{data: [], total: 0} = Requests.list_requests(filters: filter)
    #   end)
    # end
  end

  # describe "record_request!/3" do
  #   test "when data is valid, creates an request" do
  #     request_id = request_id("req")
  #     [_, phx_request_id] = request_id |> String.split("_", parts: 2)
  #     Logger.metadata(request_id: phx_request_id)

  #     request_params = %{
  #       data: %{id: "id2"},
  #       livemode: false,
  #       owner_id: uuid(),
  #       resource_id: "resource_id",
  #       resource_object: "resource_object",
  #       type: "resource.created"
  #     }

  #     audit_request_1 = Requests.record_request!(request_params)
  #     audit_request_2 = Requests.record_request!(request_params)

  #     assert %Request{} = audit_request_1
  #     assert %Request{} = audit_request_2

  #     assert_in_delta DateTime.to_unix(audit_request_1.created_at), DateTime.to_unix(utc_now()), 5
  #     assert audit_request_1.data == %{id: "id2"}
  #     assert audit_request_1.livemode == request_params.livemode
  #     assert audit_request_1.owner_id == request_params.owner_id
  #     assert audit_request_1.request_id == request_id
  #     assert audit_request_1.resource_id == request_params.resource_id
  #     assert audit_request_1.resource_object == request_params.resource_object
  #     assert audit_request_1.type == request_params.type

  #     assert audit_request_2.sequence > audit_request_1.sequence
  #   end

  #   test "when data is invalid, raises an Ecto.InvalidChangesetError" do
  #     assert_raise Ecto.InvalidChangesetError, fn ->
  #       Requests.record_request!(%{})
  #     end
  #   end

  #   test "when non-existing types and allowed_request_types is specified, raises an Ecto.InvalidChangesetError" do
  #     request_params = params_for(:request)

  #     assert_raise Ecto.InvalidChangesetError, fn ->
  #       Requests.record_request!(request_params, allowed_request_types: [])
  #     end
  #   end
  # end

  # describe "multi/4" do
  #   test "create a multi operation with attrs" do
  #     request_id = request_id("req")
  #     [_, phx_request_id] = request_id |> String.split("_", parts: 2)
  #     Logger.metadata(request_id: phx_request_id)

  #     request_params = params_for(:request)

  #     multi =
  #       Ecto.Multi.new()
  #       |> Requests.record_request_multi(request_params)

  #     assert %Ecto.Multi{} = multi

  #     assert {:ok, %{record_request: %Request{} = audit_request}} = TestRepo.transaction(multi)

  #     assert_in_delta DateTime.to_unix(audit_request.created_at), DateTime.to_unix(utc_now()), 5
  #     assert audit_request.data == request_params.data
  #     assert audit_request.livemode == request_params.livemode
  #     assert audit_request.owner_id == request_params.owner_id
  #     assert audit_request.idempotency_key == request_params.idempotency_key
  #     assert audit_request.request_id == request_id
  #     assert audit_request.resource_id == request_params.resource_id
  #     assert audit_request.resource_object == request_params.resource_object
  #     assert audit_request.type == request_params.type
  #   end

  #   test "creates an ecto multi operation with a function" do
  #     request_params = params_for(:request)

  #     multi =
  #       Ecto.Multi.new()
  #       |> Requests.record_request_multi(fn _changes -> request_params end)

  #     assert {:ok, %{record_request: %Request{} = audit_request}} = TestRepo.transaction(multi)

  #     assert audit_request.data == request_params.data
  #     assert audit_request.type == request_params.type
  #   end

  #   test "when non-existing types and allowed_request_types is specified, returns a changeset error" do
  #     request_params = params_for(:request)

  #     multi =
  #       Ecto.Multi.new()
  #       |> Requests.record_request_multi(request_params, allowed_request_types: [])

  #     assert_raise Ecto.InvalidChangesetError, fn ->
  #       TestRepo.transaction(multi)
  #     end
  #   end
  # end

  # describe "get_request/1" do
  #   test "when the request exists, returns the request" do
  #     %{id: id} = insert!(:request)

  #     assert %Request{id: ^id} = Requests.get_request(id)
  #   end

  #   test "when then request does not exist, returns nil" do
  #     assert is_nil(Requests.get_request(uuid()))
  #   end
  # end

  # describe "get_request!/1" do
  #   test "when the request exists, returns the request" do
  #     %{id: id} = insert!(:request)

  #     assert %Request{id: ^id} = Requests.get_request!(id)
  #   end

  #   test "when then request does not exist, returns nil" do
  #     assert_raise Ecto.NoResultsError, fn ->
  #       Requests.get_request!(uuid())
  #     end
  #   end
  # end
end
