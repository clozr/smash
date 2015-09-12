recipe create_user
  + useradd -m {{user}} -G {{groups}} -s /bin/bash
  if 'sudo' in groups:
    + echo '{{user}} ALL=NOPASSWD: ALL' >> /etc/sudoers
  @d ssh_dir '/home/{{user}}/.ssh'
  @d key_dir 'keys'
  +  mkdir -p {{ssh_dir}}
  +  chmod 700 {{ssh_dir}}
  @d key user
  call security.ensure_key
  -> {{key_dir}}/{{user}}.pub /home/{{user}}/.ssh/authorized_keys 600 {{user}}:{{user}}
  # generate or copy over private keys
  for hcfg in ssh:
    @p hcfg['key_dir'] = key_dir
    call security.ensure_key hcfg
    -> {{key_dir}}/{{hcfg.key}}.key {{ssh_dir}}/{{hcfg.key}}.key 600 {{user}}:{{user}}
  # generate ssh config
  @r ssh_config {{ssh_dir}}/config 600
  # generate ssh tunnels config
  # fix permission on ssh dir
  +  chmod 700 {{ssh_dir}}
  +  chown -R {{user}}:{{user}} {{ssh_dir}}
  #  sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/' sshd_config

recipe delete_user
  + deluser {{user}}
  + rm -fR /home/{{user}}

recipe copy_public_key
  for key in public_keys
    -> {{key_dir}}/{{key}} {{ssh_dir}}/{{key}}
    -> cat {{ssh_dir}}/{{key}} >> {{ssh_dir}}/authorized_keys
    -> rm {{ssh_dir}}/{{key}}


recipe init_ssh
  @d ssh_dir '/home/{{user}}/.ssh'
  for h in ssh
    # copy over private keys
    -> {{key_dir}}/{{h.key}} {{ssh_dir}}/{{h.key}} 600
  # render combined config
  @r ssh_config {{ssh_dir}}/config 600
  # render tunnels cfg
  @r tunnels.cfg /etc/tunnels.cfg 644 root:root
