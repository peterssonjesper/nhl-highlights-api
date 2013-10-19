#!/bin/bash
bundle install
mv /var/www/nhl.jpetersson.se /var/www/old.nhl.jpetersson.se
mv `pwd` /var/www/nhl.jpetersson.se
rm -rf /var/www/old.nhl.jpetersson.se
