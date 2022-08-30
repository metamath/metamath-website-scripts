#!/bin/sh

# Script to create a Metamath system on a Debian VM
# NOTE: This script is *SPECIFICALLY* designed to be able to be re-run.
# See INSTALL.md

# By default we will also generate the website.
: ${GENERATE_WEBSITE:=y}

set -x

# Record in setting $1 the value $2
set_setting () {
  printf '%s\n' "$2" > "settings/$1"
}

# Print setting $1 given prompt $2, regex pattern $3, (optional) default $4.
# We'll use the value in "settings/$1" if it exists.
get_setting () {
  if [ $# -lt 3 ] ; then
    echo "Fatal: get_setting with only these parameters: $*" >&2
    exit 1
  fi
  mkdir -p settings/
  if [ ! -f "settings/$1" ]; then
    while true; do
      echo >&2
      echo "[$1] $2" >&2
      echo "Default: <$4> Requires: <$3>" >&2
      read -r answer
      if [ -z "$answer" ]; then # Use default on empty answer.
        answer="${4:-''}"
      fi
      if printf '%s' "$answer" | grep -qE "^($3)$" ; then
        set_setting "$1" "$answer"
        break
      fi
      echo 'Sorry, that does not match the required regex pattern.' >&2
    done
  fi
  echo "Note: Using setting $1 = $(cat "settings/$1")" >&2
  cat "settings/$1"
  return
}

# Print the message $1 and exit with failure.
fail () {
  printf '%s\n' "$1" >&2
  exit 1
}

# Main script begins here.

echo 'Beginning install, Using the settings in settings/ where available.'

# Sanity check
[ "$(whoami)" = 'root' ] || fail 'Must be root.'
[ "$(pwd)" = '/root' ] || fail 'Must be in /root directory.'

# Make sure we're installing the currently-available packages.
# Linode-specific information about this is at:
# https://www.linode.com/docs/guides/getting-started/#update-your-system-s-hosts-file
# For Ubuntu:  "You may be prompted to make a menu selection when the
# Grub package is updated on Ubuntu.  If prompted, select keep the local
# version currently installed."  -y should be OK for Debian.  See
# To use apt instead?: "sudo DEBIAN_FRONTEND=noninteractive apt upgrade"

apt-get update -y && apt-get upgrade -y

# Set up git, so we can use "git pull" to update our scripts.
apt-get install -y git
if [ ! -d .git ]; then
  git clone -n https://github.com/metamath/metamath-website-scripts.git
  mv metamath-website-scripts/.git .git
  rmdir metamath-website-scripts
  echo 'Run "git pull", then rerun this script.'
  git checkout --force main
  # Start over - the script may have changed due to "git checkout"
  exit 0
fi

# Set hostname if a different one is desired.
hostname="$(get_setting hostname 'What fully-qualified hostname do you want?' \
            '[A-Za-z0-9\.\-]+' "$(hostname)")"
if [ "$hostname" != "$(hostname)" ]; then
  echo "The system is named <$(hostname)>, not $hostname. Renaming."
  hostnamectl set-hostname "$hostname"
  hostname="$(hostname)"
fi

# Automatically install security updates, per:
# https://www.linode.com/docs/guides/how-to-configure-automated-security-updates-debian/
# We don't need "sudo"; we assume we're running this script as root

apt install -y unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

# Install fail2ban, a simple intrusion prevention system for mass logins, etc.
apt install -y fail2ban

# Install web server (nginx)
apt-get install -y nginx

# Install certbot (so we get TLS certificates for the web server)
apt-get install -y certbot python-certbot-nginx

# NOTE: The web domain name doesn't HAVE to be the hostname.
# To make future changes easier, we'll use the term "webname" for the
# web domain name, but for now assume it's the hostname. That will make
# these scripts a little easier to edit later if needed.
webname="$hostname"

# Install nginx configuration file for its webname, tweaking it
# if the host isn't us.metamath.org.

mkdir -p "/var/www/${webname}/html" # Where we'll store HTML files
nginx_config="/etc/nginx/sites-available/${webname}" # Config file location
cp -p us.metamath.org "${nginx_config}"
# This uses GNU sed extension -i
sed -E -i'' -e 's/us\.metamath\.org/'"${webname}"'/g' "${nginx_config}"
ln -f -s "${nginx_config}" /etc/nginx/sites-enabled/
systemctl restart nginx

# Install rsync to update site
apt-get install -y rsync

# Other utilities to assist future maintenance

apt-get -y install locate zip

# Install what you need to rebuild website
apt-get -y install make gawk

# Install sshd configuration tweaks
cp -p sshd_config_metamath.conf /etc/ssh/sshd_config.d/

# Install sysctl configuration tweaks (to harden the system security)
cp -p local-sysctl.conf /etc/sysctl.d/

# Install & configure uncomplicated firewall.
apt-get -y install ufw
# The firewall is simply an *extra* step, we can disable it temporarily.
# I'm more worried about accidentally losing control over the system.
ufw disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
# Allows both http and https:
ufw allow 'Nginx Full'
# We MUST do this before enabling firewall
ufw allow ssh
ufw --force enable
ufw status
ufw verbose

# TODO: This assumes we're a mirror that will use rsync to get data
# elsewhere - we eventually need to NOT assume that.

# Set up crontabs - note that "certbot renew"
#     requires that build-linode-cert.sh be run
# Keep Metamath site updated daily

cat > ,tmpcron << END
# Run certbot renewal once a month
0 3 1 * * certbot renew
# Update file database daily with "locate" package
0 5 * * * updatedb
# Safety: Forcibly tell ufw to allow ssh, in case we accidentally disable it.
0 5 * * * ufw allow ssh
# This would sync from "rsync.metamath.org":
# 7 4 * * * /root/mirrorsync.sh
END
crontab -u root ,tmpcron
rm ,tmpcron

install_cert="$(get_setting install_cert \
  "Obtain & install a new initial certificate for ${webname}?" 'y|n' 'n')"

case "$install_cert" in
y)
    # Customize for this machine
    poc_email="$(get_setting poc_email \
      "What's the email POC for ${webname}?" '.+@.+' '')"

    certbot run -n --nginx --agree-tos --redirect -m "${poc_email}" \
                -d "${webname}"

    # certbot renew --force-renewal

    # Expected results:
    #  - Congratulations! Your certificate and chain have been saved at:
    #    /etc/letsencrypt/live/linode2.metamath.org/fullchain.pem
    #    Your key file has been saved at:
    #    /etc/letsencrypt/live/linode2.metamath.org/privkey.pem
    #    Your cert will expire on 2021-09-18. To obtain a new or tweaked
    #    version of this certificate in the future, simply run certbot again
    #    with the "certonly" option. To non-interactively renew *all* of
    #    your certificates, run "certbot renew"
    #  - Your account credentials have been saved in your Certbot
    #    configuration directory at /etc/letsencrypt. You should make a
    #    secure backup of this folder now. This configuration directory will
    #    also contain certificates and private keys obtained by Certbot so
    #    making regular backups of this folder is ideal.

    # We've run the initial installer, so assume we won't do it again.
    set_setting 'install_cert' n
    ;;
esac

# If we're *generating* the pages (not just serving them), set that up.
if [ "$GENERATE_WEBSITE" = 'y' ]; then
    # Need these to rebuild metamath.exe
    apt-get -y install gcc rlwrap autoconf

    # Install what you need to rebuild LaTex things for website
    apt-get -y install texlive

    # Set up "generator" user to regenerate website
    adduser --gecos 'Metamath website generator' --disabled-password generator \
      || true

    # Copy the top-level regeneration script so "generator" will run it.
    cp -p /root/regenerate-website.sh /home/generator/

    # Chang ownership so generator can update the website contents
    chown -R generator.generator "/var/www/${webname}/html"

    # Create a crontab entry for "generator" to regenerate daily.
    crontab -u generator - <<DONE
0 4 * * * /home/generator/regenerate-website.sh
DONE

    # Do the initial site load (will take a while) - or just wait for cron
    # echo 'You may run this down to force resync: /root/mirrorsync.sh'
fi

apt-get clean
