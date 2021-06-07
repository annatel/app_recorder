# defmodule Plug.RecordRequest do
#   @moduledoc """
#   A plug to record the request. It supports an idempotency_key.

#   If an idempotency key exists as the "idempotency_key" HTTP request header,
#   then that value will be used assuming it is between 20 and 200 characters.
#   If it is not, the idempotency key will be ignored.

#   The idempotency key is added to the Logger metadata as `:idempotency_key` and the response as
#   the "idempotency_key" HTTP header.

#   To use this plug, just plug it into the desired module:

#       plug Plug.RecordRequest

#   ## Options

#     * `:http_header` - The name of the HTTP *request* header to check for
#       existing idempotency_key. This is also the HTTP *response* header that will be
#       set with the idempotency_key. Default value is "idempotency-key"

#           plug Plug.RecordRequest, http_header: "custom-idempotency-key"

#   """

#   require Logger

#   alias Plug.Conn

#   @behaviour Plug

#   @idempotency_key_header "idempotency-key"
#   @idempotent_replayed_header "idempotent-replayed"
#   @original_request_id_header "original-request-id"

#   def init(opts) do
#     %{
#       idempotency_key_header: Keyword.get(opts, :http_header, @idempotency_key_header),
#       get_original_request_fun: Keyword.get(opts, :get_original_request),
#       save_request_data_fun: Keyword.get(opts, :save_request_data),
#       save_response_data_fun: Keyword.get(opts, :save_response_data),
#       response_content_type_fun: Keyword.get(opts, :response_content_type),
#       response_raw_body_fun: Keyword.get(opts, :response_raw_body),
#       response_status_fun: Keyword.get(opts, :response_status)
#     }
#   end

#   def call(%Plug.Conn{} = conn, %{idempotency_key_header: idempotency_key_header} = opts) do
#     opts = Map.put(opts, :idempotency_key, get_idempotency_key(conn, idempotency_key_header))

#     conn
#     |> set_idempotency_key(opts)
#     |> put_original_request(opts)
#     |> save_current_request_data(opts)
#     |> maybe_resp_original_request()
#     |> Plug.Conn.register_before_send(fn conn ->
#       save_response_data.(conn, conn.assigns.current_request)

#       conn
#     end)
#   end

#   defp get_idempotency_key(conn, http_header) do
#     case Conn.get_req_header(conn, http_header) do
#       [val | _] -> if valid_idempotency_key?(val), do: val, else: nil
#       [] -> nil
#     end
#   end

#   defp set_idempotency_key(%Plug.Conn{} = conn, %{idempotency_key: nil}), do: conn

#   defp set_idempotency_key(%Plug.Conn{} = conn, %{
#          idempotency_key_header: idempotent_key_header,
#          idempotency_key: idempotency_key
#        }) do
#     Logger.metadata(idempotency_key: idempotency_key)

#     conn
#     |> Conn.put_resp_header(http_header, idempotency_key)
#   end

#   defp put_original_request(%Plug.Conn{method: "POST"} = conn, %{
#          idempotency_key: idempotency_key,
#          get_original_request_fun: get_original_request_fun
#        })
#        when not is_nil(idempotency_key) do
#     conn
#     |> Conn.put_private(:original_request, get_original_request_fun.(idempotency_key))
#   end

#   defp put_original_request(%Plug.Conn{} = conn, _), do: conn

#   defp save_current_request_data(conn, %{save_request_data_fun: save_request_data_fun}) do
#     original_request = Map.get(conn.assigns, :original_request)
#     current_request = save_request_data_fun.(conn, original_request)

#     conn
#     |> Conn.put_private(:current_request, current_request)
#   end

#   defp maybe_resp_original_request(
#          conn,
#          %{
#            response_content_type_fun: response_content_type_fun,
#            response_raw_body_fun: response_raw_body_fun,
#            response_status_fun: response_status_fun
#          }
#        ) do
#     original_request = Map.get(conn.assigns, :original_request)

#     if original_request do
#       conn
#       |> Conn.put_resp_header(@idempotent_replayed_header, true)
#       |> Conn.put_resp_header(@original_request_id_header, original_request.id)
#       |> put_resp_content_type(response_content_type_fun(original_request))
#       |> send_resp(response_status_fun(original_request), response_raw_body_fun(original_request))
#       |> halt()
#     else
#       conn
#     end
#   end

#   defp valid_idempotency_key?(s), do: byte_size(s) in 20..200

#   defp get_response_body(%Plug.Conn{} = conn) do
#     conn
#     |> get_response_content_type()
#     |> case do
#       "application/json; charset=utf-8" -> Phoenix.json_library().decode!(conn.resp_body)
#       _ -> conn.resp_body
#     end
#   end

#   defp get_response_content_type(%Plug.Conn{} = conn) do
#     case List.keyfind(conn.resp_headers, "content-type", 0) do
#       {_, content_type} -> content_type
#       _ -> conn.resp_body
#     end
#   end
# end
