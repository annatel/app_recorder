defmodule AppRecorder.OutgoingRequests.OutgoingRequestQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.OutgoingRequests.OutgoingRequest
end
