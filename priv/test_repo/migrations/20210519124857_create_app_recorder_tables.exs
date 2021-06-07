defmodule AppRecorder.TestRepo.Migrations.CreateAppRecorderTables do
  use Ecto.Migration

  def up do
    AppRecorder.Migrations.up(from_version: 0, to_version: 1)
  end

  def down do
    AppRecorder.Migrations.down(from_version: 1, to_version: 0)
  end
end
