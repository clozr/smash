recipe install
  + apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
  + echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
  + apt-get update
  + apt-get install mongodb-org

recipe configure
  + {{db_cmd}} stop
  # dir configuration
  + mkdir -p {{db_dir}}
  for d in ['data', 'log']
    + mkdir -p {{db_dir}}/{{d}}
  # fix dir permission
  # ln -sf {{db_dir}}/journal {{db_dir}}/data/journal
  + chmod -R 750 {{db_dir}}
  + chown -R {{sys_user}}:{{sys_group}} {{db_dir}}

  # copy over configuration
  @r mongod.conf _mongod.conf
  -> _mongod.conf {{db_conf}}
  + mv /etc/{{db_conf}}  /etc/{{db_conf}}.old
  + mv {{db_conf}} /etc/{{db_conf}}
  + chmod 755 /etc/{{db_conf}}
  #
  + {{db_cmd}} start
  - mongo --eval "printjson(rs.initiate())"

recipe secure
  # define vars
  @d admin_passwd generate_password(12)
  @d app_admin_passwd generate_password(12)
  @d db_passwd generate_password(12)
  # render files
  @r db_settings.template  backup/db_settings.py
  @r secure_mongo.template backup/secure_mongo.js
  @r mongorc.template backup/mongorc.js
  @r mongo_dump.sh backup/mongo_dump.sh
  @r mongo_restore.sh backup/mongo_restore.sh
  # upload files
  -> backup/db_settings.py ~/db_settings.py
  -> backup/secure_mongo.js ~/secure_mongo.js
  -> backup/mongorc.js ~/.mongorc.js
  -> backup/mongo_dump.sh ~/mongo_dump.sh
  -> backup/mongo_restore.sh ~/mongo_restore.sh
  - chmod 700 ~/mongo_dump.sh
  - chmod 700 ~/mongo_restore.sh
  - chmod 700 ~/.mongorc.js
  # secure mongo databases
  - mongo secure_mongo.js
  - rm -f ~/secure_mongo.js

recipe backup
  @r mongo_dump.sh
  -> mongo_dump.sh
  - chmod 700 ~/mongo_dump.sh
  for db,policy in dbs
    if policy == 'backup'
      - rm -fR {{bkdir}}/data/{{db}}
      - ~/mongo_dump.sh {{db}} {{bkdir}}
      - cd {{bkdir}} && tar zcvf db-{{db}}.tgz data/{{db}}
      <- {{bkdir}}/db-{{db}}.tgz backup/db-{{db}}.tgz


recipe restore
  @r mongo_restore.sh
  -> mongo_restore.sh
  for db,policy in dbs
    if policy == 'backup'
      -> backup/db-{{db}}.tgz db-{{db}}.tgz
      - tar zxvf db-{{db}}.tgz
      - mongorestore --db {{db}} data/{{db}}/{{db}}

recipe sync
  for db,policy in dbs
    if policy == 'sync'
      - cd {{app_name}} && python run.py drop_collections {{db}}
      ! mongodump --db {{db}} --out data/{{db}}
      ! tar zcvf db-{{db}}.tgz data/{{db}}
      -> db-{{db}}.tgz db-{{db}}.tgz
      - tar zxvf ~/db-{{db}}.tgz
      # mongorestore --db {{db}} data/{{db}}/{{db}}
      - ~/mongo_restore.sh {{db}} data

recipe add
  call install
  call mongodb.configure 'ubuntu.mongodb'
  call mongodb.secure 'ubuntu.mongodb'


