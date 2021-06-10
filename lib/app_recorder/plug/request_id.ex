defmodule AppRecorder.Plug.RequestId do
  @moduledoc """
  A plug for generating a unique request id for each request.

  The generated request id will be in the format "uq8hs30oafhj5vve8ji5pmp7mtopc08f".

  The request id is added to the Logger metadata as `:request_id` and the response as
  the "x-request-id" HTTP header. To see the request id in your log output,
  configure your logger backends to include the `:request_id` metadata:

      config :logger, :console, metadata: [:request_id]

  It is recommended to include this metadata configuration in your production
  configuration file.

  You can also access the `request_id` programmatically by calling
  `Logger.metadata[:request_id]`. Do not access it via the request header, as
  the request header value has not been validated and it may not always be
  present.

  To use this plug, just plug it into the desired module:

      plug AppRecorder.Plug.RequestId

  Based on Plug.RequestId

  ## Options

    * `:http_header` - The name of the HTTP *request* header to check for
      existing request ids. This is also the HTTP *response* header that will be
      set with the request id. Default value is "x-request-id"

          plug Plug.RequestId, http_header: "custom-request-id"

  """

  require Logger
  alias Plug.Conn
  @behaviour Plug

  @impl true
  @spec init(keyword) :: binary
  def init(opts) do
    Keyword.get(opts, :http_header, "x-request-id")
  end

  @impl true
  @spec call(Conn.t(), binary) :: Conn.t()
  def call(conn, request_id_header) do
    request_id = AppRecorder.RequestId.generate_request_id("req")

    conn
    |> set_request_id(request_id_header, request_id)
  end

  defp set_request_id(conn, header, request_id) do
    Logger.metadata(request_id: request_id)
    Conn.put_resp_header(conn, header, request_id)
  end
end
