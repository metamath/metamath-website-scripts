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

You'll have an equivalent username on the mirror.metamath.org server,
but with only these characters: `a-z0-9_-` (notice no `.`). So mirror site
`cn.metamath.org` will have username `cnmetamathorg`.

### Create ssh public/private keypair

Use `ssh-keygen` to create a public/private keypair, and send us the public key
(the *.pub file)

We support the following formats:

> dsa | ecdsa | ecdsa-sk | ed25519 | ed25519-sk | rsa

This public key will be copied into the file `mirrors/FQDN`
in this `metamath-website-scripts` directory, and then the admin will
rerun `git pull; build-system.sh` on the main mirror.metamath.org system.

You will need to install the SSH private key on the server running the
mirror, on the account that will be running rsync via ssh.

### Periodically run rsyn over ssh

Once installed, set up your system to
periodically (say 1/hour) run rsync over ssh to acquire the update.
Your command would probably look like this (replace each FQDN with yours,
e.g., `cn.metamath.org`, and USERNAME with your username, that is,
the FQDN without a period):

~~~~
rsync -e ssh -a USERNAME@mirror.metamath.org: /var/www/FQDN/
~~~~

You may need to add options if you store the SSH private key in a
nonstandard location or want to do something else special.

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
