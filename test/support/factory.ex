defmodule AppRecorder.Factory do
  use AntlUtilsEcto.Factory, repo: AppRecorder.TestRepo

  use AppRecorder.Factory.Event
  use AppRecorder.Factory.Request
  use AppRecorder.Factory.OutgoingRequest

  @spec request_id(nil | binary) :: binary
  def request_id(prefix \\ nil) do
    AppRecorder.RequestId.generate_request_id(prefix)
  end
end
