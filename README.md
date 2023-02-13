Metamath website scripts

This repository has various scripts to set up or reconfigure a Metamath website.

If you want to propose changes to the basic configuration or execution
processes of a Metamath website runs, please propose a change as a pull request.
Most of the time you don't want a change in this repository, instead,
you'll want to propose a change to one of the Metamath database repositories
(usually the [set.mm repository](https://github.com/metamath/set.mm)),
Metamath-related programs such as the
[metamath-exe](https://github.com/metamath/metamath-exe) repository,
or the
[metamath-website-seed repository](https://github.com/metamath/metamath-website-seed).
This metamath-website-scripts repository contains the scripts and configuration
that load the Metamath databases, runs them through Metamath-related programs,
and combines them with the metamath-website-seed files to produce
the working Metamath website.

If you just want to change the configuration of the existing Metamath website,
and you have the necessary permissions (e.g., David A. Wheeler and
Mario Carneiro), change this repo's "main" branch.
Then log in with `ssh root@us.metamath.org`
and run (at the home directory `/root`):

~~~~sh
git pull
./build-system.sh
~~~~


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

File `us.metamath.org` file is the configuration file for the nginx web server.

These scripts implement the following principles:

* [Infastructure as Code](https://www.redhat.com/en/topics/automation/what-is-infrastructure-as-code-iac). To configure a system, you edit a version-controlled script (here) and run it. That way, you can easily recreate a system on the same or a different hosting environment.
* Idempotent. You can re-run configuration scripts as many times as you want without harm (they'll just change the system to implement the intended configuration).
* Imperative scripts. Some systems use a declarative approach, but implementing
  that requires a lot of infrastructure. We just use simple imperative
  commands that do nothing if the task is already done.
* Directories over file edits. On Linux most services have ".d" directories
  where you can insert files to control configuration. We prefer doing that
  over editing directories, because that's easier *and* doesn't interfere
  with system updates.
* Pragmatic. Eventually everything will be almost completely automated, but
  it's okay if we don't start that way.
* Git as transport. We use git to do version control, so we may as well
  use git to transport the scripts to the systems that will run them.
