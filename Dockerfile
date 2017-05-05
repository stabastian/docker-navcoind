FROM ubuntu:latest
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
      software-properties-common

# Boost library 
RUN apt-get install -y \
      libboost-system-dev libboost-filesystem-dev libboost-chrono-dev \
      libboost-program-options-dev libboost-test-dev libboost-thread-dev

# Install Berkeley DB
RUN add-apt-repository ppa:bitcoin/bitcoin -y && \
      apt-get update && \
      apt-get install --no-install-recommends -y libdb4.8-dev libdb4.8++-dev

# Git cli
RUN apt-get update && apt-get install -y git-core && rm -rf /var/lib/apt/lists/*

# Default GIT information
ENV GIT_REPO  https://github.com/navcoindev/navcoin-core.git
ENV GIT_REVISION 4.0.2.1

      # Optional Firewall-jumping support
      #apt-get install libminiupnpc-dev (see --with-miniupnpc and--enable-upnp-default)

      # ZMQ dependencies:
      #apt-get install libzmq3-dev (provides ZMQ API 4.x) 

RUN git clone $GIT_REPO && \
      cd navcoin-core && \
      git branch $GIT_REVISION && \
      git checkout $GIT_REVISION && \
      ./autogen.sh && \
      ./configure --enable-hardening --without-gui --without-miniupnpc && \
      make && \
      make install
