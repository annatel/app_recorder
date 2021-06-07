# AppRecorder

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/annatel/app_recorder/main?cacheSeconds=3600&style=flat-square)](https://github.com/annatel/app_recorder/actions) [![GitHub issues](https://img.shields.io/github/issues-raw/annatel/app_recorder?style=flat-square&cacheSeconds=3600)](https://github.com/annatel/app_recorder/issues) [![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?cacheSeconds=3600?style=flat-square)](http://opensource.org/licenses/MIT) [![Hex.pm](https://img.shields.io/hexpm/v/app_recorder?style=flat-square)](https://hex.pm/packages/app_recorder) [![Hex.pm](https://img.shields.io/hexpm/dt/app_recorder?style=flat-square)](https://hex.pm/packages/app_recorder)

Record events

## Installation

AppRecorder is published on [Hex](https://hex.pm/packages/app_recorder).  
The package can be installed by adding `app_recorder` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:app_recorder, "~> 0.1.0"}
  ]
end
```

After the packages are installed you must create a database migration for each version to add the app_recorder tables to your database:

```elixir
defmodule AppRecorder.TestRepo.Migrations.CreateAppRecorderTables do
  use Ecto.Migration

  def up do
        AppRecorder.Migrations.V1.up()
    AppRecorder.Migrations.Events.V1.up()
    AppRecorder.Migrations.Requests.V1.up()
  end

  def down do
        AppRecorder.Migrations.V1.down()
    AppRecorder.Migrations.Events.V1.down()
    AppRecorder.Migrations.Requests.V1.down()
  end
end

```

This will run all of AppRecorder's versioned migrations for your database. Migrations between versions are idempotent and will never change after a release. As new versions are released you may need to run additional migrations.

Now, run the migration to create the table:

```sh
mix ecto.migrate
```