FROM elixir:1.9.0-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y wget

RUN wget -qO- https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential nodejs

RUN npm install -g --save-dev webpack webpack-cli \
    && npm update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y firejail \
    && chown root:root /usr/bin/firejail \
    && chmod u+s /usr/bin/firejail

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg \
    && mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/ \
    && wget https://packages.microsoft.com/config/debian/9/prod.list \
    && mv prod.list /etc/apt/sources.list.d/microsoft-prod.list \
    && chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg \
    && chown root:root /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y dotnet-sdk-5.0

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y unzip

WORKDIR /opt
RUN wget http://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-10.1.0/gcc-10.1.0.tar.gz \
    && tar zxf gcc-10.1.0.tar.gz \
    && cd gcc-10.1.0 \
    && ./contrib/download_prerequisites \
    && ./configure --disable-multilib \
    && make -j 4 \
    && make install \
    && cd .. \
    && rm -rf gcc-10.1.0

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3.5

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mono-complete mono-mcs

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y golang-go

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y rustc

RUN apt-get update --fix-missing \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y default-jdk

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y r-base r-base-dev r-recommended \
    r-cran-car \
    r-cran-caret \
    r-cran-data.table \
    r-cran-dplyr \
    r-cran-gdata \
    r-cran-ggplot2 \
    r-cran-lattice \
    r-cran-lme4 \
    r-cran-mapdata \
    r-cran-maps \
    r-cran-maptools \
    r-cran-mgcv \
    r-cran-mvtnorm \
    r-cran-nlme \
    r-cran-reshape \
    r-cran-stringr \
    r-cran-survival \
    r-cran-tidyr \
    r-cran-xml \
    r-cran-xml2 \
    r-cran-xtable \
    r-cran-xts \ 
    r-cran-zoo

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y ghc

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
