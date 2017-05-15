#!/bin/bash

CORE_FOLDER='/app/navcoin-core'
BDB_FOLDER="/app/db4"
UI_FOLDER="/home/stakebox/UI"
GIT_REPO_CORE=${GIT_REPO_CORE:https://github.com/NAVCoin/navcoin-core.git}
GIT_REVISION_CORE=${GIT_REVISION_CORE:v4.0.3}
GIT_REPO_UI=${GIT_REPO_UI:https://github.com/NAVCoin/navpi.git}
GIT_REVISION_UI=${GIT_REVISION_UI:master}


if [ ! -d "$CORE_FOLDER" ]; then
  git clone -b $GIT_REVISION_CORE $GIT_REPO_CORE $CORE_FOLDER
 
  # INSTALL WEB INTERFACE 
  if [ ! -d "$UI_FOLDER" ]; then
    git clone -b $GIT_REVISION_UI $GIT_REPO_UI $UI_FOLDER

    chown www-data:www-data -R $UI_FOLDER
  fi

  # INSTALL BARKELY DB
  if [ ! -d "$BDB_FOLDER" ]; then
    mkdir -p $BDB_FOLDER

    cd /tmp

    # Fetch the source and verify that it is not tampered with
    wget 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz'
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c

    # -> db-4.8.30.NC.tar.gz: OK
    tar -xzvf db-4.8.30.NC.tar.gz

    # Build the library and install to our prefix
    cd db-4.8.30.NC/build_unix/

    # Note: Do a static build so that it can be embedded into the executable, instead of having to find a .so at runtime
    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_FOLDER
    make install

    rm -fr /tmp/*
  fi
  
  # INSTALL CORE
  cd $CORE_FOLDER

  # Install and configure navcoin
  ./autogen.sh
  ./configure LDFLAGS="-L${BDB_FOLDER}/lib/" CPPFLAGS="-I${BDB_FOLDER}/include/" --enable-hardening --without-gui --enable-upnp-default
  make
  make install
fi

# Start navcoin daemon
navcoind -daemon

# Start apache
apache2-foreground
