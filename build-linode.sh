#!/bin/sh
# Script to create a Metamath mirror on an empty Debian VM
#
# 1. Login as root on a freshly created VM, and set hostname:
#    hostnamectl set-hostname DOMAIN_NAME
# 2. Download and run this script, ./build-linode
# 2. Update DNS A record for "us.metamath.org" to point to <ip>; wait
#    until "host us.metamath.org" returns this <ip>
# 3. Run
#        ./build-linode-cert.sh <ip> <ip6> <domain>
#
# Note: downloading the Metamath site with rsync takes ~1 hour

# Example creating an empty Linode VM:
#   https://login.linode.com/
#     Log in:  nmegill <passwd>
#   https://cloud.linode.com/linodes
#     Click on Create a Linode
#     Select Images "Debian 10", Region "Newark, NJ", Linode Plan "Nanode 1GB",
#         root password, optionally change Linode Label
#         to e.g. debian-us-metamath-org
#       Here is what the console showed:
#         Linode Label:  debian-us-metamath-org
#         Linode ID: 27874250
#         Created: 2021-06-20 19:00
#         2600:3c03::f03c:92ff:fe21:a2a7/128
#         root password:  <root-passwd>
#         SSH Access:   ssh root@173.255.232.114
#         LISH Console via SSH:  ssh -t nmegill@lish-newark.linode.com debian-us-east-001
#
# ssh root@173.255.232.114
# Run build-linode.sh on freshly-created VM

# NOTE: This script is *SPECIFICALLY* designed to be able to be re-run.

# Instructions for updating DNS at domainmonger.com:
#
# domainmonger.com
#     Login
#         nm@alum.mit.edu
#         <passwd>
#         Login
#     Domains  (3rd from left in blue bar, not the black bar above it)
#       -> My Domains
#         (metamath.org) -> (wrench symbol) -> Manage domain
#            Manage
#              DNS Management
#                Manage A Records
#                  ADD A NEW A RECORD
#                     -or-
#                  EDIT (in row for existing record)
#                     -or-
#                  DELETE (in row for existing record)
#                Domainmonger has these notes:
#                    To specify any Host Name, use the asterisk "*"
#                    To specify no Host Name, use the at char "@"
#

# Useful links (suggested by Cris, although I haven't tried the procedures)
# https://www.linode.com/docs/guides/remote-access#transferring-ip-addresses
# https://certbot.eff.org/docs/using.html#manual
# https://community.letsencrypt.org/t/move-to-another-server/77985
# http://nateserk.com/2019/tech/migrate-letsencrypt-ssl-certificates-to-a-different-server-guide/

# Customize for this machine

# At one time this script set the hostname using:
# hostnamectl set-hostname us.metamath.org
# (replace us.metamath.org with the needed hostname).
# However, to make it easy to rerun, we no longer do that.

echo 'Note: we assume you have already run hostnamectl set-hostname DOMAIN_NAME'

# https://www.linode.com/docs/guides/getting-started/#update-your-system-s-hosts-file
# For Ubuntu:  "You may be prompted to make a menu selection when the
# Grub package is updated on Ubuntu.  If prompted, select keep the local
# version currently installed."  -y should be OK for Debian.  See
# To use apt instead?: "sudo DEBIAN_FRONTEND=noninteractive apt upgrade"
apt-get update -y && apt-get upgrade -y

apt-get install nginx -y

# Install rsync to update site
apt-get install -y rsync

# Other utilities to assist future maintenance
apt-get -y install gcc
apt-get -y install locate
apt-get -y install zip
apt-get -y install rlwrap

# Try to solve annoying ssh timeouts that give the message:
#     "client_loop: send disconnect: Connection reset by peer"
grep -q '^TCPKeepAlive' /etc/ssh/sshd_config
if [ $? -eq 1 ] ; then
	  echo 'Adding keep-alive to /etc/ssh/sshd_config...'
	    cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config-old
	      echo 'TCPKeepAlive yes' >> /etc/ssh/sshd_config
	        echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config
		  echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config
		    systemctl restart ssh.service
		      # or:  /etc/init.d/ssh restart
	      else
		        # If sshd_config already has keep-alive then don't add it again
			  echo '/etc/ssh/sshd_config was not changed'
fi

# Install git, enabling easy download/updates of scripts
apt-get install -y git

# For certbot
apt-get install -y certbot python-certbot-nginx

# Begin set up of git, so that we can use "git pull" to get future versions.
# The first "git pull" may have a complication (we may have to remove a
# conflicting file), but this is easier than other bootstrapping approaches.
if [ ! -d .git ]; then
  git clone -n https://github.com/metamath/metamath-website-scripts.git
  mv metamath-website-scripts/.git .git
fi


# Automatically install security updates, per:
# https://www.linode.com/docs/guides/how-to-configure-automated-security-updates-debian/
# We don't need "sudo"; we assume we're running as root
apt install -y unattended-upgrades
systemctl enable unattended-upgrades
systemctl start unattended-upgrades

# (run certbot using script from build-linode-cert.sh, or
#  copy over files from another server
#
#     cd /etc
#     tar -czf ~/letsencrypt.tgz letsencrypt
#     cp /etc/nginx/sites-available/default ~/default
#
# then sftp them to this server, then run
#
#   cp -p /etc/nginx/sites-available/default /etc/nginx/sites-available/default-old
#   cp -p ~/default /etc/nginx/sites-available/
#   cd /etc
#   mv /etc/letsencrypt/ /etc/letsencrypt-old/
#   tar -xzf ~/letsencrypt.tgz
#   systemctl reload nginx

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
echo "0 5 * * * updatedb
END
crontab -u root ,tmpcron
rm ,tmpcron

# Do the initial site load (will take a while) - or just wait for cron
# /root/mirrorsync.sh
