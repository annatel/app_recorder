defmodule AppRecorder.Plug.RecordRequest do
  use Plug.ErrorHandler
  require Logger

  alias Plug.Conn

  alias AppRecorder.Requests
  alias AppRecorder.Requests.Request

  @behaviour Plug

  @idempotency_key_header "idempotency-key"
  @idempotent_replayed_header "idempotent-replayed"
  @original_request_id_header "original-request-id"

  @spec init(keyword) :: keyword
  def init(_), do: []

  @spec call(Conn.t(), keyword) :: Conn.t()
  def call(%Plug.Conn{} = conn, _) do
    idempotency_key = get_idempotency_key(conn, @idempotency_key_header)

    conn
    |> set_idempotency_key(idempotency_key)
    |> put_original_request()
    |> save_current_request_data()
    |> maybe_resp_original_request()
    |> Plug.Conn.register_before_send(fn conn ->
      record_response_data!(conn, conn.assigns.current_request)

      conn
    end)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    Conn.send_resp(conn, conn.status, "Something went wrong")
  end

  defp get_idempotency_key(conn, idempotency_key_header) do
    case Conn.get_req_header(conn, idempotency_key_header) do
      [val | _] -> if valid_idempotency_key?(val), do: val, else: nil
      [] -> nil
    end
  end

  defp set_idempotency_key(%Plug.Conn{} = conn, nil), do: conn

  defp set_idempotency_key(%Plug.Conn{} = conn, idempotency_key) do
    Logger.metadata(idempotency_key: idempotency_key)

    conn
    |> Conn.put_private(:idempotency_key, idempotency_key)
    |> Conn.put_resp_header(@idempotency_key_header, idempotency_key)
  end

  defp put_original_request(
         %Plug.Conn{method: "POST", private: %{idempotency_key: idempotency_key}} = conn
       )
       when is_binary(idempotency_key) do
    conn
    |> Conn.put_private(
      :original_request,
      AppRecorder.Requests.get_request_by(idempotency_key: idempotency_key)
    )
    |> Conn.put_private(:replayed_request?, not is_nil(conn.private.original_request))
  end

  defp put_original_request(%Plug.Conn{} = conn),
    do: conn |> Conn.put_private(:replayed_request?, false)

  defp save_current_request_data(conn) do
    original_request = conn.private[:original_request]
    current_request = record_request!(conn, original_request)

    conn
    |> Conn.put_private(:current_request, current_request)
  end

  defp maybe_resp_original_request(conn) do
    original_request = conn.private[:original_request]

    if conn.private.replayed_request? do
      conn
      |> Conn.put_resp_header(@idempotent_replayed_header, true)
      |> Conn.put_resp_header(@original_request_id_header, original_request.id)
      |> Conn.put_resp_content_type(response_content_type(original_request))
      |> Conn.send_resp(response_status(original_request), response_body(original_request))
      |> Conn.halt()
    else
      conn
    end
  end

  defp valid_idempotency_key?(s), do: byte_size(s) in 20..200

  defp record_request!(%Plug.Conn{} = conn, original_request) do
    conn
    |> build_request_attrs(original_request)
    |> AppRecorder.Requests.record_request!()
  end

  defp record_response_data!(%Plug.Conn{} = conn, request) do
    request
    |> Requests.update_request!(%{
      success: conn.status in 200..299,
      response_data: %{
        body: response_body(conn),
        headers: response_headers(conn),
        status: conn.status
      }
    })
  end

  defp build_request_attrs(%Plug.Conn{} = conn, nil) do
    owner_id_field_name = elem(AppRecorder.owner_id_field(), 0)

    attrs =
      %{
        id: Logger.metadata()[:request_id],
        created_at: DateTime.utc_now(),
        idempotency_key: conn.private.idempotency_key,
        request_data: %{
          body: request_body(conn),
          client_ip: Logger.metadata()[:remote_ip],
          headers: request_headers(conn),
          method: conn.method,
          path: conn.request_path,
          query_params: conn.query_params,
          query_string: conn.query_string,
          url: url(conn)
        }
      }
      |> Map.put(owner_id_field_name, Map.get(conn.assigns, owner_id_field_name))

    if AppRecorder.with_livemode?(),
      do: Map.put(attrs, :livemode, conn.assigns["livemode?"]),
      else: attrs
  end

  defp build_request_attrs(%Plug.Conn{} = conn, %Request{} = request) do
    conn
    |> build_request_attrs(nil)
    |> Map.merge(%{
      response_data: %{
        body: response_body(request),
        headers: response_headers(conn),
        status: response_status(request)
      },
      source: request.source,
      success: request.success
    })
  end

  defp request_body(%Conn{} = conn) do
    request_content_type = request_content_type(conn)

    cond do
      request_content_type =~ "application/json" ->
        Jason.encode!(conn.body_params)

      request_content_type =~ "application/x-www-form-urlencoded" ->
        Jason.encode!(conn.body_params)

      true ->
        ""
    end
  end

  defp request_content_type(%Conn{} = conn) do
    case List.keyfind(conn.req_headers, "content-type", 0) do
      {_, content_type} -> content_type
      nil -> nil
    end
  end

  defp request_headers(%Conn{} = conn) do
    ["content-type", "origin", "referer", "user-agent", "x-tls-version"]
    |> Enum.reduce(%{}, fn header, acc ->
      {_, value} = List.keyfind(conn.req_headers, header, 0)

      Map.put(acc, header, value)
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp response_body(%Conn{} = conn) do
    response_content_type = response_content_type(conn)

    cond do
      response_content_type =~ "application/json" ->
        Jason.encode!(conn.resp_body)

      true ->
        conn.resp_body
    end
  end

  defp response_body(%Request{response_data: %{body: body}}), do: body

  defp response_content_type(%Conn{} = conn) do
    case List.keyfind(conn.resp_headers, "content-type", 0) do
      {_, content_type} -> content_type
      nil -> nil
    end
  end

  defp response_content_type(%Request{response_data: %{headers: headers}}),
    do: Map.get(headers, "content-type")

  defp response_headers(%Conn{} = conn) do
    [
      "content-length",
      "content-type",
      "idempotency-key",
      @idempotent_replayed_header,
      @original_request_id_header,
      "request-id"
    ]
    |> Enum.reduce(%{}, fn header, acc ->
      {_, value} = List.keyfind(conn.resp_headers, header, 0)

      Map.put(acc, header, value)
    end)
    |> Enum.reject(&is_nil(&1))
  end

  defp response_status(%Request{response_data: %{status: status}}), do: status

  defp url(%Conn{port: port} = conn) when port in [80, 443] do
    "#{conn.scheme}://#{conn.host}#{conn.request_path}"
  end

  defp url(%Conn{} = conn) do
    "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}"
  end
end
