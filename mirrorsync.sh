#!/bin/sh
rsync -vrltS -z --delete --delete-after --block-size=400 \
    rsync://rsync.metamath.org/metamath /var/www/html
