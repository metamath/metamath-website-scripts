Metamath website scripts

This repository has various scripts to set up a Metamath website.

A website's name must be set up with a DNS registrar.
If it's *.metamath.org, it must be setup with the DNS registar
for metamath.org.
(At the time of this writing, we use domainmonger as our registar).
We currently have domainmonger set up so any request to
"metamath.org" or "www.metamath.org" is redirected to
`http://us.metamath.org/mm.html`, so that people can find the mirrors;
we could just redirect to the relevant us.metamath.org page
if that would be easier.

You then need to set up a machine. Currently us.metamath.org is
set up as a machine on Linode. For this to work:

* create a linode instance.
* log in as root
* Set up its hostname, e.g. `hostnamectl set-hostname us.metamath.org`
  (`hostnamectl` adjusts other files like `/etc/hostname`)
* Install git and the scripts using git:

~~~~
apt-get install -y git
if [ ! -d .git ]; then
  git clone -n https://github.com/metamath/metamath-website-scripts.git
  mv metamath-website-scripts/.git .git
  git checkout main
  rmdir metamath-website-scripts
fi
~~~~

Then run the install script:
run `build-linode.sh`


You can always update the scripts later with `git pull`
