defmodule AppRecorder.Events.EventQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Events.Event
end
