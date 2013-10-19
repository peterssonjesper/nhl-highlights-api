#!/bin/bash
bundle install
mv /var/www/nhl.jpetersson.se/api /var/www/nhl.jpetersson.se/api.old
mv `pwd` /var/www/nhl.jpetersson.se/api
rm -rf /var/www/nhl.jpetersson.se/api.old
