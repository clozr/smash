recipe deploy_upstart_services
  @r tunnels.cfg
  ! sudo mv tunnels.cfg /etc/tunnels.cfg
  ! sudo chmod 644 /etc/tunnels.cfg
  ! sudo chown root:root /etc/tunnels.cfg
  for service in services
    @r {{service.template}} {{service.name}}.conf
    ! sudo mv {{service.name}}.conf /etc/init
    ! sudo chmod 644 /etc/init/{{service.name}}.conf
    ! sudo chown root:root /etc/init/{{service.name}}.conf
    ! sudo ln -sf /lib/init/upstart-job  /etc/init.d/{{service.name}}
    ! sudo update-rc.d {{service.name}} defaults
  for service in services
    if service['start']
      ! sudo service {{service.name}} start

