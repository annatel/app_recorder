defmodule AppRecorder.RequestsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.Requests
  alias AppRecorder.Requests.Request

  describe "list_requests/1" do
    test "returns the list of requests ordered by the id descending" do
      %{id: id_1} = insert!(:request)

      assert %{data: [%Request{id: ^id_1}], total: 1} = Requests.paginate_requests(100, 1)
      assert %{data: [], total: 1} = Requests.paginate_requests(100, 2)
    end

    test "order_by" do
      %{id: id1} = insert!(:request)
      %{id: id2} = insert!(:request)

      assert %{data: [%{id: ^id2}, %{id: ^id1}]} = Requests.paginate_requests(100, 1)

      assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
               Requests.paginate_requests(100, 1, order_by_fields: [asc: :id])
    end

    test "filters" do
      request = insert!(:request)

      [
        [id: request.id],
        [idempotency_key: request.idempotency_key],
        [livemode: request.livemode],
        [owner_id: request.owner_id],
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
        [source: "source"],
        [success: !request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [], total: 0} = Requests.paginate_requests(100, 1, filters: filter)
      end)
    end
  end

  describe "record_request!/3" do
    test "when data is valid, creates an request" do
      request_id = request_id()
      request_params = params_for(:request, id: request_id)

      request = Requests.record_request!(request_params)
      assert %Request{} = request

      assert_in_delta DateTime.to_unix(request.created_at), DateTime.to_unix(utc_now()), 5
      assert request.idempotency_key == request_params.idempotency_key
      assert request.livemode == request_params.livemode
      assert request.request_data == request_params.request_data
      assert request.response_data == request_params.request_data
      assert request.owner_id == request_params.owner_id
      assert request.source == request_params.source
      assert request.success == request_params.success
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
    end
  end

  describe "get_request_by/1" do
    test "when the request exists, returns the request" do
      %{id: id, idempotency_key: idempotency_key} = insert!(:request)

      assert %Request{id: ^id} = Requests.get_request_by(idempotency_key: idempotency_key)
    end

    test "when then request does not exist, returns nil" do
      assert is_nil(Requests.get_request_by(idempotency_key: uuid()))
    end
  end
end
