# Installation instructions

This is how to set up a metamath machine (mirror website or generator).

Currently us.metamath.org is set up as a machine on Linode.
You can recreate a linode instance.

Everything here assumes you're running on Debian Linux.

# Create a node (e.g., on Linode)

Create a VM to run on. Here's how to do this on Linode:

~~~~
  https://login.linode.com/
    Log in:  nmegill <passwd>
  https://cloud.linode.com/linodes
    Click on Create a Linode
    Select Images "Debian 11", Region "Newark, NJ", Linode Plan "Nanode 1GB",
        root password, optionally change Linode Label
        to e.g. debian-us-metamath-org
      Here is what the console showed:
        Linode Label:  debian-us-metamath-org
        Linode ID: 27874250
        Created: 2021-06-20 19:00
        2600:3c03::f03c:92ff:fe21:a2a7/128
        root password:  <root-passwd>
        SSH Access:   ssh root@173.255.232.114
        LISH Console via SSH:
          ssh -t nmegill@lish-newark.linode.com debian-us-east-001
~~~~

## Setup DNS

Log in to your DNS registar (for us.metamath.org that is domainmonger).
Update DNS A and AAAA records, e.g., for "us.metamath.org" to point to the
ip address (e.g., as shown in `hostname -i).

For example, here's how to update DNS and domainmonger.com:

~~~~
    Login
        nm@alum.mit.edu
        <passwd>
        Login
    Domains  (3rd from left in blue bar, not the black bar above it)
      -> My Domains
        (metamath.org) -> (wrench symbol) -> Manage domain
           Manage
             DNS Management
               Manage A Records
                 ADD A NEW A RECORD
                    -or-
                 EDIT (in row for existing record)
                    -or-
                 DELETE (in row for existing record)
               Domainmonger has these notes:
                   To specify any Host Name, use the asterisk "*"
                   To specify no Host Name, use the at char "@"
~~~~

## Download scripts

* log in as root, e.g., `ssh root@IP-ADDRESS-GIVEN`
* Install git and the install scripts using git:

~~~~
apt-get install -y git
if [ ! -d .git ]; then
  git clone -n https://github.com/metamath/metamath-website-scripts.git
  mv metamath-website-scripts/.git .git
  git checkout main
  rmdir metamath-website-scripts
fi
~~~~

## Run (re-)install script

Run the (re-)install script:

~~~~sh
./build-system.sh
~~~~

You can always update the scripts later with `git pull`
and then re-run the install script.

## Setup TLS certificats

Run this to do the initial setup of certbot to get TLS certificates.
You can omit setting POC_EMAIL, and you can also set HOSTNAME=...
the same way to set the external cert:

~~~~
POC_EMAIL='your_email' ./build-linode-cert.sh
~~~~

## Sync

Downloading the Metamath site with rsync takes ~1 hour.

## Useful links

Here are links for more information:

* https://www.linode.com/docs/guides/remote-access#transferring-ip-addresses
* https://certbot.eff.org/docs/using.html#manual
* https://community.letsencrypt.org/t/move-to-another-server/77985
* http://nateserk.com/2019/tech/migrate-letsencrypt-ssl-certificates-to-a-different-server-guide/
