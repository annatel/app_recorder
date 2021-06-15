defmodule AppRecorder.Factory.OutgoingRequest do
  alias AppRecorder.OutgoingRequests.OutgoingRequest

  defmacro __using__(_opts) do
    quote do
      def build(:outgoing_request, attrs) do
        %OutgoingRequest{
          destination: "destination_#{System.unique_integer()}",
          client_error_message: "client_error_message_#{System.unique_integer()}",
          id: request_id("out_req"),
          request_body: "request_body_#{System.unique_integer()}",
          request_method: "GET",
          request_url: "request_url_#{System.unique_integer()}",
          requested_at: utc_now(),
          response_http_status: 200,
          response_body: "response_body_#{System.unique_integer()}",
          responded_at: utc_now(),
          source: "source_#{System.unique_integer()}",
          success: true
        }
        |> struct!(attrs)
      end
    end
  end
end
