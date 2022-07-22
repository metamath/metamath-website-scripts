#!/bin/sh
# regenerate-website - download & regenerate the Metamath website

set -eu

# This script by default downloads, generates, and pushes its results.
# Set environment variables to skip some steps:
: ${REGENERATE_DOWNLOAD:=y}
: ${REGENERATE_GENERATE:=y}
: ${REGENERATE_PUSH:=y}

case "${REGENERATE_DOWNLOAD}" in
y)
    mkdir -p repos
    if [ ! -d repos/set.mm ]; then
        (
            cd repos;
            git clone --depth 1 https://github.com/metamath/set.mm.git
        )
    fi
    (
        cd repos/set.mm
        git pull  --depth 10
    )
;;
esac

exit 0
