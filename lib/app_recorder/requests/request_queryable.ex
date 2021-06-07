defmodule AppRecorder.Requests.RequestQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Requests.Request
end
