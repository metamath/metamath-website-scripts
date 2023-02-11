#!/bin/sh
# regenerate-website - download & regenerate the Metamath website contents

# Print the message $1 and exit with failure.
fail () {
  printf '%s\n' "$1" >&2
  exit 1
}

# set -eu
set -x

if [ "$(whoami)" = 'root' ]; then
    fail 'DO NOT run this as roo!! Execute /root/run-regenerate.sh instead!!'
fi

start_date="$(date)"

# This script by default downloads, generates, and pushes its results.
# Set environment variables to skip some steps:
: ${REGENERATE_DOWNLOAD:=y}
: ${REGENERATE_GENERATE:=y}
: ${REGENERATE_PUSH:=y}
: ${COPY_TO_WEBPAGE:=y}

# Previously we generated all files to
# </opt/dts/mmmaster/metamathsite/>
# (e.g., </opt/dts/mmmaster/metamathsite/metamath/>)
# but now we'll just generate to METAMATHSITE which is $HOME/metamathsite
METAMATHSITE="$HOME/metamathsite"

cd

# Configure git so it'll stop complaining about certain kinds of pulls
git config --global pull.rebase false


# Erase & re-download what we need.

case "${REGENERATE_DOWNLOAD}" in
y)
    # We once downloaded set.mm using git, but that creates a *huge* .git
    # directory we don't need. Downloading *just* the tarball from GitHub
    # is actually quite fast, so we'll just do it every time if we
    # are going to download it at all.
    rm -fr repos
    # cd repos; git clone https://github.com/metamath/set.mm.git
    mkdir -p repos/set.mm
    (
        cd repos/set.mm
        curl -L https://api.github.com/repos/metamath/set.mm/tarball | \
            tar xz --strip=1
    )
    # Download metamath source code.
    './repos/set.mm/scripts/download-metamath'

    # TODO: To ensure that we start from a clean slate, we'll
    # REMOVE the $METAMATH directory, load in its seed,
    # regenerate parts, & move them in. This is very inefficient, but it ensures
    # we know exactly what we're starting from.

    rm -fr "$METAMATHSITE/"
    mkdir -p "$METAMATHSITE/"
    (
    cd "$METAMATHSITE"
    SEED='https://api.github.com/repos/metamath/metamath-website-seed/tarball'
    curl -L "$SEED" | tar xz --strip=1
    )

    # Bring in latex styles.
    curl -L 'https://raw.githubusercontent.com/metamath/metamath-book/master/narrow.sty' > "$METAMATHSITE/latex/narrow.sty"
    curl -L 'https://raw.githubusercontent.com/metamath/metamath-book/master/normal.sty' > "$METAMATHSITE/latex/normal.sty"
;;
esac

# Regenerate website, now that we've downloaded all the external files.

case "${REGENERATE_GENERATE}" in
y)
    mkdir -p "$METAMATHSITE/metamath/"
    mkdir -p "$METAMATHSITE/mpegif/"

    # Rebuild metamath.exe, so we're certain to use the latest one.
    './repos/set.mm/scripts/build-metamath'

    # Copy databases in.
    cp -p repos/set.mm/*.mm "$METAMATHSITE/metamath/"

    cd "$METAMATHSITE"
    sh -x "$HOME/install.sh" >install.log 2>&1
    cd "$HOME"

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

# echo 'DEBUG: Showing the files generaated so far'
# find "$METAMATHSITE"

case "${COPY_TO_WEBPAGE}" in
y)
    if [ -d /var/www/us.metamath.org ]; then
        mkdir /var/www/us.metamath.org/html
        echo 'Copying generated pages to website'
        rsync -a --delete "$METAMATHSITE/" /var/www/us.metamath.org/html/
    fi
;;
esac

end_date="$(date)"
echo
echo "Start: ${start_date}"
echo "End:   ${end_date}"

exit 0
