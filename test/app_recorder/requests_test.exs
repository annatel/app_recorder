defmodule AppRecorder.RequestsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.Requests
  alias AppRecorder.Requests.Request

  describe "paginate_requests/1" do
    test "returns the list of requests ordered by the id descending" do
      %{id: id_1} = insert!(:request)

      assert %{data: [%Request{id: ^id_1}], page_size: 100, page_number: 1, total: 1} =
               Requests.paginate_requests(100, 1)

      assert %{data: [], page_size: 100, page_number: 2, total: 1} =
               Requests.paginate_requests(100, 2)
    end

    test "order_by" do
      %{id: id1} = insert!(:request)
      %{id: id2} = insert!(:request)

      assert %{data: [%{id: ^id2}, %{id: ^id1}]} = Requests.paginate_requests(100, 1)

      assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
               Requests.paginate_requests(100, 1, order_by_fields: [asc: :id])
    end

    test "filters" do
      %{related_resources: [related_resource]} = request = insert!(:request)

      [
        [id: request.id],
        [idempotency_key: request.idempotency_key],
        [livemode: request.livemode],
        [owner_id: request.owner_id],
        [related_resource_id: related_resource.resource_id],
        [related_resource_id: [related_resource.resource_id]],
        [related_resource_object: related_resource.resource_object],
        [source: request.source],
        [success: request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_request], total: 1} = Requests.paginate_requests(100, 1, filters: filter)
      end)

      [
        [id: request_id()],
        [idempotency_key: "idempotency_key"],
        [livemode: !request.livemode],
        [owner_id: uuid()],
        [related_resource_id: "related_resource_id"],
        [related_resource_object: "related_resource_object"],
        [source: "source"],
        [success: !request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [], total: 0} = Requests.paginate_requests(100, 1, filters: filter)
      end)
    end

    test "includes" do
      %{related_resources: [%{id: id_1}, %{id: id_2}]} =
        insert!(:request,
          related_resources: [build(:request_related_resource), build(:request_related_resource)]
        )

      %{data: [request], total: 1} = Requests.paginate_requests(100, 1)
      assert Ecto.assoc_loaded?(request.related_resources)

      assert [%{id: ^id_1}, %{id: ^id_2}] = request.related_resources
    end
  end

  describe "record_request!/3" do
    test "when data is valid, creates an request" do
      request_id = request_id("req")

      %{related_resources: [related_resource_params]} =
        request_params = params_for(:request, id: request_id)

      request = Requests.record_request!(request_params)
      assert %Request{} = request

      assert_in_delta DateTime.to_unix(request.created_at), DateTime.to_unix(utc_now()), 5
      assert request.idempotency_key == request_params.idempotency_key
      assert request.livemode == request_params.livemode
      assert request.owner_id == request_params.owner_id
      assert [related_resource] = request.related_resources
      assert related_resource.resource_id == related_resource_params.resource_id
      assert related_resource.resource_object == related_resource_params.resource_object
      assert request.request_data == request_params.request_data
      assert request.response_data == request_params.request_data
      assert request.source == request_params.source
      assert request.success == request_params.success
    end

    test "id, livemode, request_data and owner_id are required" do
      assert_raise Ecto.InvalidChangesetError, ~r/id: \[{\"can't be blank\"/, fn ->
        Requests.record_request!(%{})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/request_data: \[{\"can't be blank\"/, fn ->
        Requests.record_request!(%{request_data: nil, response_data: nil})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/livemode: \[{\"can't be blank\"/, fn ->
        Requests.record_request!(%{})
      end

      assert_raise Ecto.InvalidChangesetError, ~r/owner_id: \[{\"can't be blank\"/, fn ->
        Requests.record_request!(%{})
      end
    end

    test "when data is invalid, raises an Ecto.InvalidChangesetError" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Requests.record_request!(%{})
      end
    end
  end

  describe "get_request/1" do
    test "when the request exists, returns the request" do
      %{id: id} = insert!(:request)

      assert %Request{id: ^id} = Requests.get_request(id)
    end

    test "when the id is not right prefixed, returns nil" do
      request = insert!(:request)
      request_id = String.replace(request.id, "req", "prefix")
      assert is_nil(Requests.get_request(request_id))
    end

    test "when then request does not exist, returns nil" do
      assert is_nil(Requests.get_request(request_id()))
      assert is_nil(Requests.get_request(request_id("req")))
    end
  end

  describe "get_request_by/1" do
    test "when the request exists, returns the request" do
      %{id: id, idempotency_key: idempotency_key} = insert!(:request)

      assert %Request{id: ^id} = Requests.get_request_by(idempotency_key: idempotency_key)
    end

    test "filters" do
      %{id: request_id, idempotency_key: idempotency_key} = request = insert!(:request)

      [
        [id: request.id],
        [livemode: request.livemode],
        [owner_id: request.owner_id],
        [source: request.source],
        [success: request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{id: ^request_id} =
                 Requests.get_request_by([idempotency_key: idempotency_key], filters: filter)
      end)

      [
        [id: request_id()],
        [livemode: !request.livemode],
        [owner_id: uuid()],
        [source: "source"],
        [success: !request.success]
      ]
      |> Enum.each(fn filter ->
        assert is_nil(
                 Requests.get_request_by([idempotency_key: idempotency_key], filters: filter)
               )
      end)
    end

    test "when then request does not exist, returns nil" do
      assert is_nil(Requests.get_request_by(idempotency_key: uuid()))
    end
  end
end
