defmodule AppRecorder.OutgoingRequestsTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  alias AppRecorder.OutgoingRequests
  alias AppRecorder.OutgoingRequests.OutgoingRequest

  describe "paginate_outgoing_requests/1" do
    test "returns the list of requests ordered by the id descending" do
      %{id: id_1} = insert!(:outgoing_request)

      assert %{data: [%OutgoingRequest{id: ^id_1}], page_number: 1, page_size: 100, total: 1} =
               OutgoingRequests.paginate_outgoing_requests(100, 1)

      assert %{data: [], page_number: 2, page_size: 100, total: 1} =
               OutgoingRequests.paginate_outgoing_requests(100, 2)
    end

    test "order_by" do
      %{id: id1} = insert!(:outgoing_request)
      %{id: id2} = insert!(:outgoing_request)

      assert %{data: [%{id: ^id2}, %{id: ^id1}]} =
               OutgoingRequests.paginate_outgoing_requests(100, 1)

      assert %{data: [%{id: ^id1}, %{id: ^id2}]} =
               OutgoingRequests.paginate_outgoing_requests(100, 1, order_by_fields: [asc: :id])
    end

    test "filters" do
      outgoing_request = insert!(:outgoing_request)

      [
        [id: outgoing_request.id],
        [destination: outgoing_request.destination],
        [request_method: outgoing_request.request_method],
        [request_url: outgoing_request.request_url],
        [response_http_status: outgoing_request.response_http_status],
        [source: outgoing_request.source],
        [success: outgoing_request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_outgoing_request], total: 1} =
                 OutgoingRequests.paginate_outgoing_requests(100, 1, filters: filter)
      end)

      [
        [id: request_id("out_req")],
        [destination: "destination"],
        [request_method: "request_method"],
        [request_url: "request_url"],
        [response_http_status: 0],
        [source: "source"],
        [success: !outgoing_request.success]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [], total: 0} =
                 OutgoingRequests.paginate_outgoing_requests(100, 1, filters: filter)
      end)
    end
  end

  describe "record_outgoing_request!/3" do
    test "when data is valid, creates an request" do
      outgoing_request_params = params_for(:outgoing_request)

      outgoing_request = OutgoingRequests.record_outgoing_request!(outgoing_request_params)
      assert %OutgoingRequest{} = outgoing_request

      refute is_nil(outgoing_request.id)
      assert outgoing_request.destination == outgoing_request_params.destination
      assert outgoing_request.requested_at == outgoing_request_params.requested_at
      assert outgoing_request.request_body == outgoing_request_params.request_body
      assert outgoing_request.request_headers == outgoing_request_params.request_headers
      assert outgoing_request.request_method == outgoing_request_params.request_method
      assert outgoing_request.request_url == outgoing_request_params.request_url
      assert outgoing_request.source == outgoing_request_params.source
    end

    test "when data is invalid, raises an Ecto.InvalidChangesetError" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        OutgoingRequests.record_outgoing_request!(%{})
      end
    end
  end

  describe "get_outgoing_request/1" do
    test "when the request exists, returns the request" do
      %{id: id} = insert!(:outgoing_request)

      assert %OutgoingRequest{id: ^id} = OutgoingRequests.get_outgoing_request(id)
    end

    test "when the id is not right prefixed, returns nil" do
      request = insert!(:outgoing_request)
      request_id = String.replace(request.id, "out_req", "prefix")
      assert is_nil(OutgoingRequests.get_outgoing_request(request_id))
    end

    test "when then request does not exist, returns nil" do
      assert is_nil(OutgoingRequests.get_outgoing_request(request_id()))
      assert is_nil(OutgoingRequests.get_outgoing_request(request_id("req")))
      assert is_nil(OutgoingRequests.get_outgoing_request(request_id("out_req")))
    end
  end
end
