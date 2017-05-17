#!/bin/bash

BDB_FOLDER="/usr/local/berkeley-db-4.8"
UI_FOLDER="/home/stakebox/UI"
GIT_REPO_CORE=${GIT_REPO_CORE:-'https://github.com/NAVCoin/navcoin-core.git'}
GIT_REVISION_CORE=${GIT_REVISION_CORE:-'v4.0.3'}
GIT_REPO_UI=${GIT_REPO_UI:-'https://github.com/NAVCoin/navpi.git'}
GIT_REVISION_UI=${GIT_REVISION_UI:-'master'}

if [ hash navcoind 2>/dev/null ]; then
  cd /tmp
  git clone -b $GIT_REVISION_CORE $GIT_REPO_CORE navcoin-core
 
  # INSTALL WEB INTERFACE 
  if [ ! -d "$UI_FOLDER" ]; then
    gosu navcoin git clone -b $GIT_REVISION_UI $GIT_REPO_UI $UI_FOLDER
  fi

  # INSTALL BARKELY DB
  if [ ! -d "$BDB_FOLDER" ]; then
    mkdir -p $BDB_FOLDER

    wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c
    tar -xzvf db-4.8.30.NC.tar.gz
    cd db-4.8.30.NC/build_unix/

    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_FOLDER
    make install
  fi
  
  # INSTALL CORE
  cd navcoin-core

  # Install and configure navcoin
  ./autogen.sh
  ./configure LDFLAGS="-L${BDB_FOLDER}/lib/" CPPFLAGS="-I${BDB_FOLDER}/include/" --enable-hardening --without-gui --enable-upnp-default
  make
  make install

  rm -fr /tmp/*
fi

# Start navcoin daemon
gosu navcoin navcoind -daemon

# Start apache
apache2-foreground