VERSION 0.6

elixir-base:
    FROM --platform=$BUILDPLATFORM elixir:1.14.3-alpine
    WORKDIR /app
    RUN apk add --no-progress --update openssh-client git build-base
    RUN mix local.rebar --force && mix local.hex --force

deps:
    ARG MIX_ENV
    FROM +elixir-base
    ENV MIX_ENV="$MIX_ENV"
    COPY mix.exs .
    COPY mix.lock .
    RUN mix deps.get --only "$MIX_ENV"
    RUN mix deps.compile

lint:
    FROM --build-arg MIX_ENV="dev" +deps
    COPY --dir lib .
    COPY .formatter.exs .
    RUN mix deps.unlock --check-unused
    RUN mix format --check-formatted
    RUN mix compile --warnings-as-errors

test:
    FROM earthly/dind:alpine
    WORKDIR /test
    RUN apk add --no-progress --update mysql-client postgresql-client

    COPY --dir config lib priv test .

    ARG PG_IMG="postgres:13.3"
    ARG MYSQL_IMG="mysql:8.0"

    WITH DOCKER --pull "$PG_IMG" --pull "$MYSQL_IMG" --load elixir:latest=+deps --build-arg MIX_ENV="test"
        RUN timeout=$(expr $(date +%s) + 60); \

            docker run --name pg --network=host -d -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=app_recorder "$PG_IMG"; \
            docker run --name mysql --network=host -d -e MYSQL_ROOT_PASSWORD=root "$MYSQL_IMG"; \

            while ! pg_isready --host=127.0.0.1 --port=5432 --quiet; do \
                test "$(date +%s)" -le "$timeout" || (echo "timed out waiting for postgres"; exit 1); \
                echo "waiting for postgres"; \
                sleep 1; \
            done; \

            while ! mysqladmin ping --host=127.0.0.1 --port=3306 --protocol=TCP --silent; do \
                test "$(date +%s)" -le "$timeout" || (echo "timed out waiting for mysql"; exit 1); \
                echo "waiting for mysql"; \
                sleep 1; \
            done; \

            docker run \
                --rm \
                -e DATABASE_TEST_URL="ecto://root:root@127.0.0.1:3306/app_recorder" \
                -e DATABASE_TEST_REPO_ADAPTER="myxql" \
                -e MIX_ENV=test \
                -e EX_LOG_LEVEL=warning \
                --network host \
                -v "$PWD/config:/app/config" \
                -v "$PWD/lib:/app/lib" \
                -v "$PWD/priv:/app/priv" \
                -v "$PWD/test:/app/test" \
                -w /app \
                --name app_recorder_mysql \
                elixir:latest mix test --cover; \

            docker run \
                --rm \
                -e DATABASE_TEST_URL="ecto://postgres:postgres@127.0.0.1/app_recorder" \
                -e DATABASE_TEST_REPO_ADAPTER="postgres" \
                -e MIX_ENV=test \
                -e EX_LOG_LEVEL=warning \
                --network host \
                -v "$PWD/config:/app/config" \
                -v "$PWD/lib:/app/lib" \
                -v "$PWD/priv:/app/priv" \
                -v "$PWD/test:/app/test" \
                -w /app \
                --name app_recorder_postgres \
                elixir:latest mix test;
    END

check-tag:
    FROM +elixir-base

    COPY mix.exs .

    ARG TAG
    ARG APP_VERSION=$(mix app.version)

    IF [ ! -z $TAG ] && [ ! $TAG == $APP_VERSION ]
        RUN echo "TAG '$TAG' has to be equal to APP_VERSION '$APP_VERSION'" && false
    END
