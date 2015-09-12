recipe ensure_key
    @d key_file '{{key_dir}}/{{key}}.key'
    ! echo {{key_file}}
    if not os.path.isfile(key_file)
      ! mkdir -p {{key_dir}} && cd {{key_dir}} && ssh-keygen -t rsa -f {{key}} -N '' && mv {{key}} {{key}}.key

recipe ensure_keys
  for hcfg in ssh:
    @p hcfg['key_dir'] = key_dir
    call ensure_key hcfg

recipe enable_ufw_firewall
  - apt-get install -y ufw
  - ufw default deny incoming
  - ufw default allow outgoing
  for service in ufw_open_services
    - ufw allow '{{service}}'
  - ufw enable

recipe copy_public_key
  @d ssh_dir '/home/{{user}}/.ssh'
  for h in ssh
    -> {{key_dir}}/{{h.key}}.pub {{ssh_dir}}/{{h.key}}.pub
    -> cat {{ssh_dir}}/{{key}}.pub >> {{ssh_dir}}/authorized_keys
    + rm {{ssh_dir}}/{{key}}.pub

recipe create_tunnel
  @r tunnels.cfg /etc/tunnels.cfg 644 root:root

