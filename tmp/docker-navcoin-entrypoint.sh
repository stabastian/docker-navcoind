#!/bin/bash

CORE_FOLDER='/navcoin/navcoin-core'
BDB_FOLDER="/usr/local/berkeley-db-4.8"
UI_FOLDER="/home/stakebox/UI"
GIT_REPO_CORE=${GIT_REPO_CORE:-'https://github.com/NAVCoin/navcoin-core.git'}
GIT_REVISION_CORE=${GIT_REVISION_CORE:-'v4.0.3'}
GIT_REPO_UI=${GIT_REPO_UI:-'https://github.com/NAVCoin/navpi.git'}
GIT_REVISION_UI=${GIT_REVISION_UI:-'master'}

if [ ! -d "$CORE_FOLDER" ]; then
  exec gosu navcoin git clone -b $GIT_REVISION_CORE $GIT_REPO_CORE $CORE_FOLDER
 
  # INSTALL WEB INTERFACE 
  if [ ! -d "$UI_FOLDER" ]; then
    git clone -b $GIT_REVISION_UI $GIT_REPO_UI $UI_FOLDER
    chown -R www-data $UI_FOLDER
    chmod -R a+w $UI_FOLDER
  fi

  # INSTALL BARKELY DB
  if [ ! -d "$BDB_FOLDER" ]; then
    mkdir -p $BDB_FOLDER
    cd /tmp

    wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c
    tar -xzvf db-4.8.30.NC.tar.gz
    cd db-4.8.30.NC/build_unix/

    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_FOLDER
    make install

    rm -fr /tmp/*
  fi
  
  # INSTALL CORE
  cd $CORE_FOLDER

  # Install and configure navcoin
  exec gosu navcoin ./autogen.sh
  exec gosu navcoin ./configure LDFLAGS="-L${BDB_FOLDER}/lib/" CPPFLAGS="-I${BDB_FOLDER}/include/" --enable-hardening --without-gui --enable-upnp-default
  exec gosu navcoin make
  exec gosu navcoin make install
fi

# Start navcoin daemon
navcoind -daemon

# Start apache
apache2-foreground
