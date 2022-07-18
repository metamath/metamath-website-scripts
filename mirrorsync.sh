#!/bin/sh
# Use rsync to copy metamath files to the posted website.
rsync -vrltS -z --delete --delete-after --block-size=400 \
    rsync://rsync.metamath.org/metamath "/var/www/$(hostname)/html"
