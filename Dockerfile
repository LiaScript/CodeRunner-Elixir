FROM elixir:1.7-slim

RUN apt-get update && \
    apt-get install -y wget unzip gnupg firejail python3.5

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update && \
    apt-get install -y build-essential nodejs

ADD . /berlin

WORKDIR /berlin
RUN mix local.hex --force && \
   mix local.rebar --force && \
   HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=620 mix deps.get --only prod

WORKDIR /berlin/apps/elab/assets/elm
RUN PATH="$PATH:/berlin/apps/lia/assets/node_modules/.bin" elm-make --yes

WORKDIR /berlin/apps/elab/assets
RUN PATH="$PATH:/berlin/apps/lia/assets/node_modules/.bin" brunch build --production

WORKDIR /berlin
RUN MIX_ENV=prod mix deps.compile --all && \
   MIX_ENV=prod mix phx.digest

#CMD MIX_ENV=prod mix ecto.migrate && \
#   MIX_ENV=prod mix run apps/elab/config/add_admin.exs && \
#   MIX_ENV=prod mix phx.server
