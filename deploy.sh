#!/bin/bash

bundle install --path vendor/bundle
mv /var/www/nhl.jpetersson.se/api /var/www/nhl.jpetersson.se/api.old
mv `pwd` /var/www/nhl.jpetersson.se/api
rm -rf /var/www/nhl.jpetersson.se/api.old

cd /var/www/nhl.jpetersson.se/api
mkdir tmp
mkdir tmp/sockets
mkdir tmp/pids
mkdir log

/etc/init.d/nhl restart
