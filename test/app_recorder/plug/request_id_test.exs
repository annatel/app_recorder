defmodule AppRecorder.Plug.RequestIdTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias AppRecorder.Plug.RequestId

  defp call(conn, opts) do
    RequestId.call(conn, RequestId.init(opts))
  end

  test "generates new request id" do
    conn = call(conn(:get, "/"), [])
    [res_request_id] = get_resp_header(conn, "x-request-id")
    meta_request_id = Logger.metadata()[:request_id]
    assert generated_request_id?(res_request_id)
    assert res_request_id == meta_request_id
  end

  test "generates new request id in custom header" do
    conn = call(conn(:get, "/"), http_header: "custom-request-id")
    [res_request_id] = get_resp_header(conn, "custom-request-id")
    meta_request_id = Logger.metadata()[:request_id]
    assert generated_request_id?(res_request_id)
    assert res_request_id == meta_request_id
  end

  defp generated_request_id?(request_id) do
    Regex.match?(~r/\A[A-Za-z0-9-_]+\z/, request_id)
  end
end
