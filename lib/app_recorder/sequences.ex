defmodule AppRecorder.Sequences do
  @moduledoc false

  @spec next_value!(atom) :: integer
  def next_value!(name) when name in [:events] do
    %{rows: [[nextval]]} =
      AppRecorder.repo().query!("SELECT app_recorder_nextval_gapless_sequence(?);", [
        to_string(name)
      ])

    nextval
  end
end
