#!/bin/sh
# regenerate-website - download & regenerate the Metamath website contents

set -eu

# This script by default downloads, generates, and pushes its results.
# Set environment variables to skip some steps:
: ${REGENERATE_DOWNLOAD:=y}
: ${REGENERATE_GENERATE:=y}
: ${REGENERATE_PUSH:=y}

cd

# Configure git so it'll stop complaining about certain kinds of pulls
git config --global pull.rebase false

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
        git pull  --depth '10'
    )
    './repos/set.mm/scripts/download-metamath'
;;
esac

# Regenerate website, now that we've downloaded all the external files.
# Previously it was all generated to
# </opt/dts/mmmaster/metamathsite/>
# (e.g., </opt/dts/mmmaster/metamathsite/metamath/>)
# but now we'll just generate to $HOME/metamathsite

case "${REGENERATE_GENERATE}" in
y)
    METAMATHSITE="$HOME/metamathsite"
    mkdir -p "$METAMATHSITE/metamath/"
    mkdir -p "$METAMATHSITE/mpegif/"

    # Rebuild metmath.exe, so we're certain to use the latest one.
    './repos/set.mm/scripts/build-metamath'

    # Copy databases in.
    cp -p repos/set.mm/*.mm "$METAMATHSITE/metamath/"

    cd "$METAMATHSITE"
    sh -x "$HOME/install.sh" >install.log 2>&1

    mkdir -p "$METAMATHSITE/mpegif/"
    # Copy .html / .raw.html files for mpe (set.mm)
    (
      cd repos/set.mm
      cp -p \
        mmbiblio.html \
        mmcomplex.raw.html \
        mmdeduction.raw.html \
        mmfrege.raw.html \
        mmhil.html \
        mmmusic.html \
        mmnatded.raw.html \
        mmrecent.html \
        mmset.raw.html \
        mmtopstr.html \
        mmzfcnd.raw.html \
        "$METAMATHSITE/mpegif"
    )

    mkdir -p "$METAMATHSITE/ilegif/"
    # Copy .html / .raw.html files for ile (iset.mm)
    # Not handled:
    # /opt/dts/mmmaster/metamathsite/ilegif/mmbiblio_IL.html
    (
      cd repos/set.mm
      cp -p \
        mmil.raw.html \
        mmrecent_IL.html \
        "$METAMATHSITE/ilegif/"
    )

    cp -p repos/set.mm/mm_100.html "$METAMATHSITE/"

;;
esac

echo 'DEBUG: Showing the files generaated so far'
find "$METAMATHSITE"

exit 0
