recipe configure
  + {{nginx_cmd}} stop
  # NGINX CONFIG
  @d ssl_dir '{{nginx_dir}}/ssl'
  @r nginx.main.conf {{nginx_dir}}/nginx.conf 640 root:root
  + rm -f {{nginx_dir}}/sites-enabled/default
  + ufw allow 'Nginx Full'
  + ufw enable
  + {{nginx_cmd}} start

recipe add_domain
  + {{nginx_cmd}} stop
  @d ssl_dir '{{nginx_dir}}/ssl'
  @r nginx.domain.conf {{nginx_dir}}/sites-enabled/{{domain}}.conf 640 root:root
  + mkdir -p {{ssl_dir}}
  -> ssl/{{domain}}/{{domain}}.bundle.crt {{ssl_dir}}/{{domain}}.crt 600 root:root
  -> ssl/{{domain}}/{{domain}}.key {{ssl_dir}}/{{domain}}.key 600 root:root
  + chown -R root:root {{ssl_dir}}
  + {{nginx_cmd}} start


recipe update_domain
  + {{nginx_cmd}} stop
  @d ssl_dir '{{nginx_dir}}/ssl'
  @r nginx.domain.conf {{nginx_dir}}/sites-enabled/{{domain}}.conf 640 root:root
  + {{nginx_cmd}} start

recipe check_template
  @d ssl_dir '{{nginx_dir}}/ssl'
  @r nginx.domain.conf _{{domain}}.conf
  ! diff _{{domain}}.conf {{domain}}.conf 

recipe install_ssl
  + {{nginx_cmd}} stop
  @d ssl_dir '{{nginx_dir}}/ssl'
  + mkdir -p {{ssl_dir}}
  -> ssl/{{domain}}/{{domain}}.bundle.crt {{ssl_dir}}/{{domain}}.crt 600 root:root
  -> ssl/{{domain}}/{{domain}}.key {{ssl_dir}}/{{domain}}.key 600 root:root
  + chown -R root:root {{ssl_dir}}
  + {{nginx_cmd}} start


recipe update
  call update_domain 'ubuntu.nginx,ubuntu.proj'

recipe check
  call check_template 'ubuntu.nginx,ubuntu.proj'
