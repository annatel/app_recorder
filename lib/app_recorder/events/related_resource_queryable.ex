defmodule AppRecorder.Events.RelatedResourceQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: AppRecorder.Events.RelatedResource
end
