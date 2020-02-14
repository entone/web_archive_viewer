FROM elixir:1.10.1-alpine as build

# # install build dependencies
RUN apk add --no-cache \
  gcc \
  g++ \
  git \
  make \
  musl-dev \
  rust \
  cargo
RUN mix do local.hex --force, local.rebar --force
WORKDIR /app

FROM build as deps

COPY mix.exs mix.lock ./

ARG MIX_ENV=prod
RUN mix deps.get --only=$MIX_ENV
RUN mix deps.compile

FROM deps as releaser
COPY . .
ENV MIX_ENV=prod
RUN mix release app

FROM alpine:3.11
RUN apk add --no-cache bash libstdc++ openssl musl-dev
WORKDIR /app
COPY --from=releaser /app/_build/prod/rel/app ./

EXPOSE 4000

ENTRYPOINT ["/app/bin/app"]
