FROM elixir:1.10.3-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y wget

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nodejs

RUN npm install -g --save-dev webpack webpack-cli \
    && npm update

RUN apt-get update \
    && apt-get upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y python3.5 mono-complete mono-mcs unzip

RUN wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y dotnet-sdk-3.1

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y firejail \
    && chown root:root /usr/bin/firejail \
    && chmod u+s /usr/bin/firejail

ADD . /berlin

WORKDIR /berlin
RUN mix local.hex --force \
    && mix local.rebar --force \
    && HEX_HTTP_CONCURRENCY=1 HEX_HTTP_TIMEOUT=620 mix deps.get --only prod

WORKDIR /berlin/apps/lia/assets
RUN npm install \
    && npm run deploy

WORKDIR /berlin/apps/lia
RUN MIX_ENV=prod mix phx.digest

WORKDIR /berlin
RUN MIX_ENV=prod mix deps.compile --all

CMD mix local.hex --force && MIX_ENV=prod mix phx.server
