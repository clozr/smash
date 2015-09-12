recipe secure
  @cfg 'socketio'
  #call user_mgr.create_user 'socketio.security'
  call security.create_tunnel
  call security.enable_ufw_firewall security

recipe create_user
  @cfg 'socketio'
  for user in users:
    if user['user'] != 'ec2-user':
      call user_mgr.delete_user user
      call user_mgr.create_user user

recipe deploy
  call pkgs.install
  call user_mgr.init_ssh 'socketio.security'
  call project.init_app 'socketio.proj'
  call project.deploy_app 'socketio.security,socketio.proj'
  call nginx.add_domain 'socketio.nginx,socketio.proj'
  call project.cleanup_upstart_services 'socketio.proj,socketio.upstart'
  call project.deploy_upstart_services 'socketio.proj,socketio.upstart'

recipe install
  call mysql.configure  'socketio.mysql'
  call mysql.secure 'socketio.mysql'
  call mysql.create_project_db 'socketio.mysql'
  call mongodb.configure 'socketio.mongodb'
  call mongodb.sync 'socketio.mongodb'
  call mongodb.secure 'socketio.mongodb'
  call nginx.configure 'socketio.nginx'
 
recipe install
  @cfg 'socketio'
  #call pkgs.add_repositories
  #call pkgs.install_pkg_groups socketio_pkgs
  #call pkgs.install_pkgs sys_pkgs
  #call pkgs.install_pkgs pyp_pkgs
  #call pkgs.install_pkgs npm_pkgs
  #call security.ensure_keys security
  call project.refresh_app proj,security
