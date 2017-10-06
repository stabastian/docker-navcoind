#!/bin/sh

set -ex

# Generate navcoin.conf
gosu navcoin nav_init

# Generate bitcoin.conf
gosu navcoin navcoind

#gosu navcoin tail -F /navcoin/.navcoin4/debug.log

apache2-foreground