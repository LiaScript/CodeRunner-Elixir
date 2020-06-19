FROM elixir:1.9.0-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y wget

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nodejs

RUN npm install -g --save-dev webpack webpack-cli \
    && npm update

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y python3.5 mono-complete mono-mcs unzip


RUN wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
    && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
    && wget https://packages.microsoft.com/config/debian/9/prod.list \
    && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
    && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
    && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https \
    && apt-get update \
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
