recipe install_pkgs
  for pkg in pkgs
    + {{install_cmd}} {{pkg}}

recipe add_repositories
  + apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  + echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
  + apt-add-repository ppa:chris-lea/node.js
  + apt-get update

recipe install_nodejs
  + apt-get update
  # apt-get install nodejs npm
  # wget http://nodejs.org/dist/v{{node_ver}}/node-v{{node_ver}}.tar.gz -O /tmp/node.tgz
  # cd /tmp && tar zxf node.tgz && cd node-v{{node_ver}} && sudo ./configure && sudo make install >> node_install.log 2>&1
  # git clone https://github.com/isaacs/npm.git
  # cd npm && sudo env PATH=$PATH make install > npm_install.log 2>&1

recipe install_ultramysql
  - cd /tmp && git clone https://github.com/esnme/ultramysql.git && cd ultramysql && sudo python setup.py build install

recipe install_pkg_groups
  for pkg_group in groups:
    call install_pkgs pkg_group

recipe install
  call pkgs.add_repositories
  call pkgs.install_pkgs 'ubuntu.sys_pkgs'
  call pkgs.install_pkgs 'ubuntu.pyp_pkgs'
  #call pkgs.install_ultramysql
  #call pkgs.install_django 'ubuntu.misc_pkgs'
  #call pkgs.install_nodejs 'ubuntu.misc_pkgs'
  #call pkgs.install_pkgs 'ubuntu.npm_pkgs'

##recipe install_mongodb
##  call pkgs.add_mongodb_repository
##  call pkgs.install_group 'ubuntu.db_pkgs'
