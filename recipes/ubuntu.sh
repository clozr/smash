recipe secure 
  call user_mgr.create_user 'ubuntu.security'
  call security.enable_ufw_firewall

recipe install
  call pkgs.install
  call mysql.configure  'ubuntu.mysql'
  call mysql.secure 'ubuntu.mysql'
  call mysql.create_project_db 'ubuntu.mysql'
  call mongodb.configure 'ubuntu.mongodb'
  call mongodb.sync 'ubuntu.mongodb'
  call mongodb.secure 'ubuntu.mongodb'
  call nginx.configure 'ubuntu.nginx'

recipe db_backup
  call mongodb.backup 'ubuntu.mongodb'

recipe deploy
  #call user_mgr.init_ssh 'ubuntu.security'
  #call project.init_app 'ubuntu.proj'
  #call project.deploy_app 'ubuntu.security,ubuntu.proj'
  #call nginx.add_domain 'ubuntu.nginx,ubuntu.proj'
  #call project.cleanup_upstart_services 'ubuntu.proj,ubuntu.upstart'
  #call project.deploy_upstart_services 'ubuntu.proj,ubuntu.upstart'

recipe refresh
  call project.stop_services 'ubuntu.proj,ubuntu.upstart'
  call project.refresh_app 'ubuntu.proj,ubuntu.upstart'
  #call project.start_services 'ubuntu.proj,ubuntu.upstart'
  #call project.poll_services 'ubuntu.proj,ubuntu.upstart'

recipe status
  call project.poll_services 'ubuntu.proj,ubuntu.upstart'

recipe security_update
  call project.stop_services 'ubuntu.proj,ubuntu.upstart'
  + apt-get update
  + apt-get dist-upgrade
  + shutdown -h now

recipe renew_ssl
  call nginx.install_ssl 'ubuntu.nginx,ubuntu.proj'

recipe restart
  call project.stop_services 'ubuntu.proj,ubuntu.upstart'
  call project.poll_services 'ubuntu.proj,ubuntu.upstart'
  call project.start_services 'ubuntu.proj,ubuntu.upstart'
  call project.poll_services 'ubuntu.proj,ubuntu.upstart'

recipe stop
  call project.stop_services 'ubuntu.proj,ubuntu.upstart'
  call project.poll_services 'ubuntu.proj,ubuntu.upstart'
 
recipe new_service
  @cfg 'ubuntu'
  @d SERVICE 'socketio'
  call project.deploy_service proj,upstart['project_services']
