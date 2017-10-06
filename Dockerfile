FROM php:5.6-apache
MAINTAINER Sebastian Ponti <sebaponti@gmail.com>

ARG USER_ID
ARG GROUP_ID

# Add user with specified (or default) user/group ids
ENV USER_ID=${USER_ID:-1000}
ENV GROUP_ID=${GROUP_ID:-1000}

# Add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
RUN groupadd -g ${GROUP_ID} navcoin \
      && useradd -u ${USER_ID} -g navcoin -s /bin/bash -m -d /navcoin navcoin

# Enviroments for building
ENV GIT_REVISION_CORE=${GIT_REVISION_CORE:-'v4.0.5'}

# Installing packages
RUN apt-get update && apt-get install -yq --no-install-recommends \
      # Build requirements
      build-essential libcurl3-dev libtool autotools-dev automake \
      pkg-config libssl-dev libevent-dev bsdmainutils libzmq3-dev \
      libqrencode-dev qrencode wget curl \
      # PHP + Apache dependencies
      php5-cli php5-curl \
      # Boost library
      libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
      libboost-program-options-dev libboost-test-dev libboost-thread-dev \
      # Firewall-jumping support (see --with-miniupnpc and--enable-upnp-default)
      libminiupnpc-dev \
      # Git cli
      git-core \
      && apt-get install -o Dpkg::Options::="--force-confold" --force-yes -yq libapache2-mod-php5 \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install gosu
RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
      && curl -o /usr/local/bin/gosu -fSL https://github.com/tianon/gosu/releases/download/1.9/gosu-$(dpkg --print-architecture) \
      && curl -o /usr/local/bin/gosu.asc -fSL https://github.com/tianon/gosu/releases/download/1.9/gosu-$(dpkg --print-architecture).asc \
      && gpg --verify /usr/local/bin/gosu.asc \
      && rm /usr/local/bin/gosu.asc \
      && chmod +x /usr/local/bin/gosu

# Install Stakebox UI
RUN cd /tmp \
     && git clone https://github.com/NAVCoin/navpi.git /home/stakebox/UI \
     && rm -fr /home/stakebox/UI/.git \
     && chown navcoin:navcoin /home/stakebox/ \
     && chown -R www-data:www-data /home/stakebox/UI

# Install Barkely DB
RUN export BDB_FOLDER="/usr/local/berkeley-db-4.8" \
     && mkdir -p $BDB_FOLDER \
     && wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' \
     && echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c \
     && tar -xzvf db-4.8.30.NC.tar.gz \
     && cd db-4.8.30.NC/build_unix/ \
     && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_FOLDER \
     && make install \
     # Install and configure navcoin core
     && cd /tmp \
     && git clone -b $GIT_REVISION_CORE https://github.com/NAVCoin/navcoin-core.git navcoin-core \
     && cd navcoin-core \
     && ./autogen.sh \
     && ./configure LDFLAGS="-L${BDB_FOLDER}/lib/" CPPFLAGS="-I${BDB_FOLDER}/include/" \
        --enable-hardening --without-gui --enable-upnp-default \
     && make \
     && make install \
     && cd && rm -fr /tmp/*

# Copy files
ADD ./conf/apache2.conf /etc/apache2/
ADD ./conf/navpi.conf /etc/apache2/sites-available/
ADD ./bin /usr/local/bin
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint

# Create ssl certificate
RUN mkdir /etc/apache2/ssl && cd /etc/apache2/ssl \
      && openssl genrsa -des3 -passout pass:x -out tmp-navpi-ssl.key 2048 \
      && openssl rsa -passin pass:x -in tmp-navpi-ssl.key -out navpi-ssl.key \
      && openssl req -new -key navpi-ssl.key -out navpi-ssl.csr \
         -subj "/C=NZ/ST=Auckland/L=Auckland/O=Nav Coin/OU=Nav Pi/CN=my.navpi.org" \
      && openssl x509 -req -days 365 -in navpi-ssl.csr -signkey navpi-ssl.key -out navpi-ssl.crt \
      && rm tmp-navpi-ssl.key navpi-ssl.csr \
      # Enable apache modules and site
      && a2enmod rewrite && a2enmod php5 && a2enmod ssl \
      && a2ensite navpi.conf && a2dissite 000-default.conf

VOLUME ["/navcoin"]

EXPOSE 44440 44444

ENTRYPOINT ["docker-entrypoint"]

CMD ["apache2-foreground"]