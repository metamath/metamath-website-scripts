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

See `INSTALL.md` for installation instructions.

The `us.metamath.org` file is the configuration file for the nginx web server.
