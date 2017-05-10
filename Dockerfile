FROM debian:latest
MAINTAINER Sebastian Ponti <sebaponti@gmail.com>

# Build requirements
RUN apt-get update && apt-get install -y \
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
      wget
#      software-properties-common

# Boost library 
RUN apt-get install -y \
      libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
      libboost-program-options-dev libboost-test-dev libboost-thread-dev

# Apache + PHP
RUN apt-get update && apt-get install -y php5 apache2 libapache2-mod-php5

# Git cli
RUN apt-get update && apt-get install -y git-core && rm -rf /var/lib/apt/lists/*

# Default GIT information
ENV GIT_REPO https://github.com/NAVCoin/navcoin-core.git
ENV GIT_REVISION 4.0.2.1

      # Optional Firewall-jumping support
      #apt-get install libminiupnpc-dev (see --with-miniupnpc and--enable-upnp-default)

      # ZMQ dependencies:
      #apt-get install libzmq3-dev (provides ZMQ API 4.x) 


WORKDIR /app

COPY docker-navcoin-entrypoint /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-navcoin-entrypoint

#VOLUME ["/code", "/data"]

# Port
EXPOSE 44440

# RPC Port
EXPOSE 44444

ENTRYPOINT ["docker-navcoin-entrypoint"]
#CMD ["navcoind --daemon"]
