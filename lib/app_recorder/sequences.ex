defmodule AppRecorder.Sequences do
  @moduledoc false

  @spec next_value!(atom) :: integer
  def next_value!(name) when name in [:events] do
    %{rows: [[nextval]]} =
      AppRecorder.repo().query!(
        "SELECT app_recorder_nextval_gapless_sequence('#{to_string(name)}');"
      )

    nextval
  end

  @spec current_value!(atom) :: integer
  def current_value!(name) when name in [:events] do
    %{rows: [[current_value]]} =
      AppRecorder.repo().query!("SELECT value FROM sequences  WHERE name = '#{to_string(name)}';")

    current_value |> String.to_integer()
  end
end
