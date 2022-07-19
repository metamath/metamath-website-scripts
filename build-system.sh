#!/bin/sh

# Script to create a Metamath system on a Debian VM
# NOTE: This script is *SPECIFICALLY* designed to be able to be re-run.
# See INSTALL.md

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
      echo "Default: <$3> Requires: <$4>" >&2
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

# Main script begins here.

echo 'Beginning install, Using the settings in settings/ where available.'

# Set hostname if a different one is desired.
hostname="$(get_setting hostname 'What fully-qualified hostname do you want?' \
            '[A-Za-z0-9\.\-]+' "$(hostname)")"
if [ "$hostname" != "$(hostname)" ]; then
  echo "The system is named <$(hostname)>, not $hostname. Renaming."
  echo TEMPORARY hostnamectl set-hostname "$hostname"
  hostname="$(hostname)"
fi

exit 0

# Make sure we're installing the currently-available packages.
# Linode-specific information about this is at:
# https://www.linode.com/docs/guides/getting-started/#update-your-system-s-hosts-file
# For Ubuntu:  "You may be prompted to make a menu selection when the
# Grub package is updated on Ubuntu.  If prompted, select keep the local
# version currently installed."  -y should be OK for Debian.  See
# To use apt instead?: "sudo DEBIAN_FRONTEND=noninteractive apt upgrade"

apt-get update -y && apt-get upgrade -y

# Install git, enabling easy download/updates of scripts.
# It should already be there, but let's make sure of it.
apt-get install -y git

# Automatically install security updates, per:
# https://www.linode.com/docs/guides/how-to-configure-automated-security-updates-debian/
# We don't need "sudo"; we assume we're running this script as root

apt install -y unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

# Install web server (nginx)
apt-get install -y nginx

# Install certbot (so we get TLS certificates for the web server)
apt-get install -y certbot python-certbot-nginx

# Install nginx configuration file for its HOSTNAME, tweaking it
# if the host isn't us.metamath.org.

mkdir -p "/var/www/${hostname}/html" # Where we'll store HTML files
nginx_config="/etc/nginx/sites-available/$hostname" # Config file location
cp -p us.metamath.org "${nginx_config}"
# This uses GNU sed extension -i
sed -E -i'' -e 's/us\.metamath\.org/'"${hostname}"'/g' "${nginx_config}"
ln -f -s "${nginx_config}" /etc/nginx/sites-enabled/
systemctl restart nginx

# Install rsync to update site
apt-get install -y rsync

# Other utilities to assist future maintenance

apt-get -y install locate zip

apt-get -y install gcc rlwrap

# Install sshd configuration tweaks
cp -p sshd_config_metamath.conf /etc/ssh/sshd_config.d/

# TODO: This assumes we're a mirror that will use rsync to get data
# elsewhere - we eventually need to NOT assume that.

# Set up crontabs - note that "certbot renew"
#     requires that build-linode-cert.sh be run
# Keep Metamath site updated daily

cat > ,tmpcron << END
7 4 * * * /root/mirrorsync.sh
# Run certbot renewal once a month
0 3 1 * * certbot renew
# Update file database daily with "locate" package
0 5 * * * updatedb
END
crontab -u root ,tmpcron
rm ,tmpcron

# certbot run -n --nginx --agree-tos --redirect -m "${email}" \
#           -d "${website_domain}"

# Do the initial site load (will take a while) - or just wait for cron
echo 'You may run this down to force resync: /root/mirrorsync.sh'
