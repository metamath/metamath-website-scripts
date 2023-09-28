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
  fail 'DO NOT run this as root!! Execute /root/run-regenerate.sh instead!!'
fi

start_date="$(date)"

# This script by default downloads, generates, and pushes its results.
# Set environment variables to skip some steps:
: ${REGENERATE_DOWNLOAD:=y}
: ${REGENERATE_GENERATE:=y}
: ${COPY_TO_WEBPAGE:=y}

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
  download_repo () {
    rm -fr repos/$2
    mkdir -p repos/$2
    (
      cd repos/$2
      curl -L https://api.github.com/repos/$1/$2/tarball/$3 \
        | tar xz --strip=1
    )
  }
  download_repo metamath set.mm mmrecent
  # download_repo metamath metamath-knife main
  # download_repo digama0 mm-web-rs master
  download_repo metamath metamath-website-seed rm_symbols
  download_repo metamath metamath-exe master
  download_repo metamath symbols rm_readme

  mkdir -p repos/metamath-book/
  for file in narrow normal; do
    curl -L https://raw.githubusercontent.com/metamath/metamath-book/master/$file.sty \
      > repos/metamath-book/$file.sty
  done
;;
esac

# Regenerate website, now that we've downloaded all the external files.

case "${REGENERATE_GENERATE}" in
y)
  # TODO: To ensure that we start from a clean slate, we'll
  # REMOVE the www directory, load in its seed,
  # regenerate parts, & move them in. This is very inefficient, but it ensures
  # we know exactly what we're starting from.
  rm -fr www/
  cp -r repos/metamath-website-seed www
  cp -r repos/metamath-exe www/metamath
  cp -r repos/symbols/symbols www/symbols

  cd www
    sh -x ../build-website.sh >install.log 2>&1
  cd ..
;;
esac

# echo 'DEBUG: Showing the files generated so far'
# find www

case "${COPY_TO_WEBPAGE}" in
y)
  if [ -d /var/www/us.metamath.org ]; then
    mkdir /var/www/us.metamath.org/html
    echo 'Copying generated pages to website'
    rsync -a --delete www/ /var/www/us.metamath.org/html/
  fi
;;
esac

end_date="$(date)"
echo
echo "Start: ${start_date}"
echo "End:   ${end_date}"

exit 0
