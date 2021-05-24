defmodule AppRecorder.Behaviour do
  @moduledoc false

  @callback list_events(keyword) :: %{data: [Event.t()], total: integer}
  @callback record_event!(map, keyword) :: Event.t()
  @callback record_event_multi(Ecto.Multi.t(), map | function, keyword) :: Ecto.Multi.t()
  @callback get_event(binary) :: Event.t() | nil
end
