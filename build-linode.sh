#!/bin/sh
# Script to create a Metamath mirror on an empty Debian VM
# Uses HOSTNAME for hostname.
# See INSTALL.md
# NOTE: This script is *SPECIFICALLY* designed to be able to be re-run.

echo 'Note: we assume you have already run hostnamectl set-hostname DOMAIN_NAME'

# Ensure HOSTNAME is set (this makes shellcheck happy)
: "${HOSTNAME:="$(hostname)"}"
echo "Hostname: $HOSTNAME"

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

mkdir -p "/var/www/${HOSTNAME}/html" # Where we'll store HTML files
nginx_config="/etc/nginx/sites-available/$HOSTNAME" # Config file location
cp -p us.metamath.org "${nginx_config}"
# This uses GNU sed extension -i
sed -E -i'' -e 's/us\.metamath\.org/'"${HOSTNAME}"'/g' "${nginx_config}"
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

# Do the initial site load (will take a while) - or just wait for cron
echo 'You may run this down to force resync: /root/mirrorsync.sh'
