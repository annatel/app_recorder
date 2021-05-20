defmodule AppRecorder.Behaviour do
  @moduledoc false

  @callback list_events(keyword) :: %{data: [Event.t()], total: integer}
  @callback new_event!(%{:owner_id => binary, optional(atom) => any}) :: Event.t()

  @callback record_event!(Event.t(), binary, map, keyword) :: Event.t()
  @callback record_event_multi(Ecto.Multi.t(), Event.t(), binary, map | function, keyword) ::
              Ecto.Multi.t()
  @callback get_event(binary) :: Event.t() | nil
end
