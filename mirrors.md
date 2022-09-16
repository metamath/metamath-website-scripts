# Mirrors

The `build-system.sh` script supports mirrors.

## Current state

At the time of this writing we have these mirrors under `.metamath.org`:

- at.metamath.org - Austria [courtesy of Digital Solutions Marco Kriegner]  
- cn.metamath.org - China [courtesy of caiyunapp.com],
  maintained by Mingli Yuan mingli dot yuan at gmail dot com
- de.metamath.org - Germany.

## How to create a mirror

First, determine the fully-qualified domain name (FQDN) you'll use.
If you want to create a mirror inside the `.metamath.org` namespace,
You need someone to modify the Metamath DNS entries (to add that entry).

### Create ssh public/private keypair

Use ssh to create a public/private keypair; and send us the public key.

This public key will be copied into the file `mirrors/FQDN`
in this `metamath-website-scripts` directory, and then the admin will
rerun `git pull; build-system.sh` on the main us.metamath.org system.

### Periodically run rsyn over ssh

Once installed, set up your system to
periodically (say 1/hour) run rsync over ssh to acquire the update.
Your command would probably look like this (replace each FQDN with yours,
e.g., `cn.metamath.org`):

~~~~
rsync -e ssh -a FQDN@mirror.metamath.org: /var/www/FQDN/
~~~~

We connect to `mirror.metamath.org` instead of `us.metamath.org` so that
we can later change to a CDN without interfering with anything.

## Background

The mirror system uses rsync over ssh.
Each mirror is given a special limited-privilege account, and logs in using
a public/private keypair.
On our side we configure ssh to only let the account use rrsync, which is
then configured to only allow access to the directory we set.
Even if an attacker gets through rrsync, the account is a limited
(no privilege) account.

Some information sources:

* https://serverfault.com/questions/965053/restricting-a-ssh-key-to-only-allow-rsync-file-transfer
* https://www.whatsdoom.com/posts/2017/11/07/restricting-rsync-access-with-ssh/
* http://gergap.de/restrict-ssh-to-rsync.html
* https://dev-notes.eu/2015/06/secure-rsync-between-servers/
