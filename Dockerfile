FROM elixir:1.8-slim

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget firejail python3.5 mono-mcs unzip && \
    apt-get autoremove && \
    apt-get autoclean && \
    apt-get clean

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nodejs && \
    apt-get autoremove && \
    apt-get autoclean && \
    apt-get clean

RUN npm install -g --unsafe-perm=true --allow-root elm
RUN npm install -g --save-dev webpack webpack-cli
RUN npm update

ADD . /berlin
EXPOSE 4000

RUN apt-get purge -y wget && \
    apt-get autoremove && \
    apt-get autoclean && \
    apt-get clean

WORKDIR /berlin
RUN mix local.hex --force; \
    mix local.rebar --force; \
    HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=620 mix deps.get --only prod

WORKDIR /berlin/apps/lia/assets
RUN rm package-lock.json && \
    npm install && \
    npm run deploy

WORKDIR /berlin
RUN MIX_ENV=prod mix deps.compile --all

WORKDIR /berlin/apps/lia
RUN MIX_ENV=prod mix phx.digest

CMD MIX_ENV=prod mix phx.server

#CMD MIX_ENV=prod mix ecto.migrate && \
#   MIX_ENV=prod mix run apps/elab/config/add_admin.exs && \
#   MIX_ENV=prod mix phx.server
