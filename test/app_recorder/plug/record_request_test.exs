defmodule AppRecorder.Plug.RecordRequestTest do
  use ExUnit.Case, async: true
  use AppRecorder.DataCase

  use Plug.Test

  require Logger

  import AppRecorder.Test.Assertions

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

    post "/valid_json" do
      send_resp(conn, 200, "{}")
    end

    post "/invalid_json" do
      send_resp(conn, 200, "{{")
    end

    get "/return_bad_request" do
      send_resp(conn, 422, "{\"status\": [\"is invalid\"]}")
    end

    get "/raise_bad_request" do
      raise %Plug.BadRequestError{}
      send_resp(conn, 200, "Welcome")
    end

    get "/timeout" do
      Task.async(fn -> :timer.sleep(10) end) |> Task.await(1)

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
      |> Plug.Conn.put_req_header("content-type", "plain/text")
      |> Plug.Conn.fetch_query_params()
      |> PlugWithRecordRequest.call([])

      assert_request_recorded(%{
        id: Logger.metadata()[:request_id],
        livemode: livemode,
        owner_id: owner_id,
        request_data: %{
          "body" => nil,
          "client_ip" => nil,
          "headers" => %{"content-type" => "plain/text"},
          "method" => "GET",
          "path" => "/",
          "query_params" => %{},
          "query_string" => "",
          "url" => "http://www.example.com/"
        },
        response_data: %{
          "body" => nil,
          "headers" => %{},
          "status" => 200
        }
      })
    end

    test "when the server returns a 422, record the body" do
      owner_id = uuid()
      livemode = false

      conn(:get, "/return_bad_request", "")
      |> Plug.Conn.assign(:livemode?, livemode)
      |> Plug.Conn.assign(:owner_id, owner_id)
      |> Plug.Conn.put_req_header("content-type", "plain/text")
      |> Plug.Conn.fetch_query_params()
      |> PlugWithRecordRequest.call([])

      assert_request_recorded(%{
        id: Logger.metadata()[:request_id],
        livemode: livemode,
        owner_id: owner_id,
        request_data: %{
          "body" => nil,
          "client_ip" => nil,
          "headers" => %{"content-type" => "plain/text"},
          "method" => "GET",
          "path" => "/return_bad_request",
          "query_params" => %{},
          "query_string" => "",
          "url" => "http://www.example.com/return_bad_request"
        },
        response_data: %{
          "body" => "{\"status\": [\"is invalid\"]}",
          "headers" => %{},
          "status" => 422
        }
      })
    end

    test "records the POST requests" do
      owner_id = uuid()
      livemode = false

      conn(:post, "/valid_json", %{})
      |> Plug.Conn.assign(:livemode?, livemode)
      |> Plug.Conn.assign(:owner_id, owner_id)
      |> Plug.Conn.put_req_header("content-type", "plain/text")
      |> Plug.Conn.fetch_query_params()
      |> PlugWithRecordRequest.call([])

      assert_request_recorded(%{
        id: Logger.metadata()[:request_id],
        livemode: livemode,
        owner_id: owner_id,
        request_data: %{
          "body" => nil,
          "client_ip" => nil,
          "headers" => %{"content-type" => "plain/text"},
          "method" => "POST",
          "path" => "/valid_json",
          "query_params" => %{},
          "query_string" => "",
          "url" => "http://www.example.com/valid_json"
        },
        response_data: %{
          "body" => "{}",
          "headers" => %{},
          "status" => 200
        }
      })
    end

    test "when the response body can't be decoded" do
      owner_id = uuid()
      livemode = false

      conn(:post, "/invalid_json", %{})
      |> Plug.Conn.assign(:livemode?, livemode)
      |> Plug.Conn.assign(:owner_id, owner_id)
      |> Plug.Conn.put_req_header("content-type", "plain/text")
      |> Plug.Conn.fetch_query_params()
      |> PlugWithRecordRequest.call([])

      assert_request_recorded(%{
        response_data: %{
          "body" => "{{",
          "headers" => %{},
          "status" => 200
        }
      })
    end
  end
end
