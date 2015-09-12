recipe configure
  + {{db_cmd}} stop
  + rm -fR {{db_root}}
  + mkdir -p {{db_dir}}
  + chmod -R 750 {{db_root}}
  + chown -R {{sys_user}}:{{sys_user}} {{db_root}}
  # app armor for ubuntu
  @d aa_conf 'usr.sbin.mysqld'
  @r {{aa_conf}} backup/{{aa_conf}}
  -> backup/{{aa_conf}} ~/{{aa_conf}}
  + cp /etc/apparmor.d/{{aa_conf}} ~/{{aa_conf}}.backup
  + mv ~/{{aa_conf}} /etc/apparmor.d/{{aa_conf}}
  + chmod 644 /etc/apparmor.d/{{aa_conf}}
  + chown root:root /etc/apparmor.d/{{aa_conf}}
  + service apparmor reload
  # install mysql server now
  + mysql_install_db --datadir={{db_dir}}
  @r {{source_conf}}  backup/my.cnf
  -> backup/my.cnf ~/my.cnf
  + mv ~/my.cnf {{dest_conf}}
  + chmod 750 {{dest_conf}} 
  + chown {{sys_user}}:{{sys_user}} {{dest_conf}}
  + {{db_cmd}} start

recipe secure
  # generate relevant password
  @d admin_passwd generate_password(12)
  # render relevant templates
  @r my.root.template backup/my.root.cnf
  @r secure_mysql.sql backup/secure_mysql.sql
  # secure mysql
  -> backup/secure_mysql.sql secure_mysql.sql
  - mysql -u root < secure_mysql.sql
  - rm -f ~/.my.cnf secure_mysql.sql


recipe create_project_db
  # generate db usee password
  @d db_passwd generate_password(12)
  # render SQL script to create db
  @r setup_project_db.sql backup/setup_project_db.sql
  @r my.user.template backup/my.user.cnf
  # create project database
  -> backup/my.root.cnf ~/.my.cnf 600
  -> backup/setup_project_db.sql ~/setup_project_db.sql
  - mysql < setup_project_db.sql
  # upload autologin configuration
  -> backup/my.user.cnf ~/.my.cnf 600
  -> data/djangodb.sql ~/djangodb.sql
  - mysql < djangodb.sql
  # cleanup
  - rm -f djangodb.sql
  - rm -f setup_project_db.sql
