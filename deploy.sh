#!/bin/bash
bundle install --path vendor/bundle
mv /var/www/nhl.jpetersson.se/api /var/www/nhl.jpetersson.se/api.old
mv `pwd` /var/www/nhl.jpetersson.se/api
rm -rf /var/www/nhl.jpetersson.se/api.old
