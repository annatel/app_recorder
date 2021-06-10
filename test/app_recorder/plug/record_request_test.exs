defmodule AppRecorder.Plug.RecordRequestTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  use Plug.Test

  require Logger

  defmodule PlugWithRecordRequest do
    use Plug.Router

    plug(AppRecorder.Plug.RequestId)
    plug(AppRecorder.Plug.RecordRequest)

    # use Plug.ErrorHandler

    plug(:match)
    plug(:dispatch)

    get "/" do
      send_resp(conn, 200, "Welcome")
    end
  end

  describe "requests are recorded" do
    test "on GET requests, records without the response body" do
      owner_id = uuid()
      livemode = false

      conn(:get, "/", "")
      |> Plug.Conn.assign(:livemode?, livemode)
      |> Plug.Conn.assign(:owner_id, owner_id)
      |> Plug.Conn.fetch_query_params()
      |> PlugWithRecordRequest.call([])

      %{data: [request]} = AppRecorder.Requests.list_requests()
      assert request.id == Logger.metadata()[:request_id]
      assert request.livemode == livemode
      assert request.owner_id == owner_id

      assert request.request_data == %{
               "body" => nil,
               "client_ip" => nil,
               "headers" => [],
               "method" => "GET",
               "path" => "/",
               "query_params" => %{},
               "query_string" => "",
               "url" => "http://www.example.com/"
             }

      assert request.response_data == %{"body" => "Welcome", "headers" => [], "status" => 200}
    end
  end
end
