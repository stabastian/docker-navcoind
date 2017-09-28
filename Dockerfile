FROM php:5.6-apache
MAINTAINER Sebastian Ponti <sebaponti@gmail.com>

ARG USER_ID
ARG GROUP_ID

# Add user with specified (or default) user/group ids
ENV USER_ID ${USER_ID:-1000}
ENV GROUP_ID ${GROUP_ID:-1000}

# Add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} navcoin \
      && useradd -u ${USER_ID} -g navcoin -s /bin/bash -m -d /navcoin navcoin

ENV GOSU_VERSION=1.9

RUN apt-get update && apt-get install -y curl

RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

RUN curl -o /usr/local/bin/gosu -fSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture) \
      && curl -o /usr/local/bin/gosu.asc -fSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture).asc \
      && gpg --verify /usr/local/bin/gosu.asc \
      && rm /usr/local/bin/gosu.asc \
      && chmod +x /usr/local/bin/gosu

# Build requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      libcurl3-dev \
      libtool \
      autotools-dev \
      automake \
      pkg-config \
      libssl-dev \
      libevent-dev \
      bsdmainutils \
      libzmq3-dev \
      libqrencode-dev \
      qrencode \
      wget

# PHP + Apache dependencies
RUN apt-get update && apt-get install -yq --no-install-recommends \
      php5-cli \
      php5-curl

RUN apt-get update && apt-get install -o Dpkg::Options::="--force-confold" --force-yes -yq libapache2-mod-php5

# Boost library
RUN apt-get install -y \
      libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
      libboost-program-options-dev libboost-test-dev libboost-thread-dev

# Firewall-jumping support (see --with-miniupnpc and--enable-upnp-default)
RUN apt-get update && apt-get install -y libminiupnpc-dev

# Git cli
RUN apt-get update && apt-get install -y git-core \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD ./bin /usr/local/bin
ADD ./conf/apache2.conf /etc/apache2/
ADD ./conf/navpi.conf /etc/apache2/sites-available/
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Create ssl certificate
RUN mkdir /etc/apache2/ssl && cd /etc/apache2/ssl \
      && openssl genrsa -des3 -passout pass:x -out tmp-navpi-ssl.key 2048 \
      && openssl rsa -passin pass:x -in tmp-navpi-ssl.key -out navpi-ssl.key \
      && openssl req -new -key navpi-ssl.key -out navpi-ssl.csr \
      -subj "/C=NZ/ST=Auckland/L=Auckland/O=Nav Coin/OU=Nav Pi/CN=my.navpi.org" \
      && openssl x509 -req -days 365 -in navpi-ssl.csr -signkey navpi-ssl.key -out navpi-ssl.crt \
      && rm tmp-navpi-ssl.key navpi-ssl.csr

# Enable apache modules and site
RUN a2enmod rewrite
RUN a2enmod php5
RUN a2enmod ssl
RUN a2ensite navpi.conf
RUN a2dissite 000-default.conf

VOLUME ["/navcoin"]

# Ports
EXPOSE 44440 44444

ENTRYPOINT ["docker-entrypoint"]