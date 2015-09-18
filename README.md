# smash
Smart Meta Automation Shell

## philosophy
*smash* is a shell scripting extension which simplifies writing scripts which can run on multiple hosts. It also provides very intuitive shortcuts for most common deployment scenarios. *smash* uses python fabric behind the scene to achieve these goals.

## requirements
To use *smash* you need python. In  addition you need the following python libraries:
 1) fabric
 2) jinja2
 3) optparse
 
## usage
 Currently, you need three folders to organize your files. This will change in future to allow more flexibility.
 1) config - Here you will have the global configuration which can be used in the scripts
 2) templates - You can keep the template files here. e.g. Templated version of mysql.conf or mongodb.conf or similar.
 3) recipes - you keep your shell command recipes here
 
 Use the following syntax to run your smash scripts.
 ```bash
 # runs the recipe install_pkgs in recipe/ubuntu.sh with remote hosts `web1`, `web2`, `web3`
 # it uses the configuration file from from config/ubuntu.py
 python smash.py -c ubuntu ubuntu.install_pkgs -H web1 web2 web3
 ```
 
 
## syntax
 Every shell commmand used in *smash recipes* have a prefix. This section describes the various prefix used to modulate the shell command.
 
### prefix *!*
 This prefix instructs to run a shell command `<cmd>` on local host:
 ```bash
 ! <cmd>
 ```
## prefix *-*
 This prefix instructs to run a shell command `<cmd>` on all specified remote hosts:
 ```bash
 - <cmd>
```
## prefix *+* 
 This prefix instructs to run a shell command `<cmd>` on all specified remote hosts in sudo mode:
```bash
+ <cmd>  # run the command on host web1, web2, web3 in sudo mode
```
Following example adds mongodb and node.js repository on ubuntu on all connected hosts.
```
  + apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  + echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
  + apt-add-repository ppa:chris-lea/node.js
  + apt-get update
```

