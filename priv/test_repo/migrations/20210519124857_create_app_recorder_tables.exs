defmodule AppRecorder.TestRepo.Migrations.CreateAppRecorderTables do
  use Ecto.Migration

  def up do
    AppRecorder.Migrations.V1.up()
    AppRecorder.Migrations.Events.V1.up()
    AppRecorder.Migrations.Requests.V1.up()
    AppRecorder.Migrations.OutgoingRequests.V1.up()
    AppRecorder.Migrations.OutgoingRequests.V2.up()
    Padlock.Mutexes.Migrations.V1.up()
  end

  def down do
    AppRecorder.Migrations.V1.down()
    AppRecorder.Migrations.Events.V1.down()
    AppRecorder.Migrations.Requests.V1.down()
    AppRecorder.Migrations.OutgoingRequests.V1.down()
    Padlock.Mutexes.Migrations.V1.down()
  end
end
