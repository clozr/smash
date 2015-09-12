recipe gen_csr
  ! mkdir -p ssl/{{domain}}
  ! cd ssl/{{domain}} && openssl req -newkey rsa:2048 -nodes -keyout {{domain}}.key -out {{domain}}.csr -subj "/C={{country}}/ST={{state}}/L={{city}}/O={{company}}/OU=IT/CN={{domain}}"

recipe create_bundle
  @d cert_name domain.replace('.', '_')
  ! cd ssl/{{domain}} && unzip {{cert_name}}.zip && cat {{cert_name}}.crt COMODORSAAddTrustCA.crt COMODORSADomainValidationSecureServerCA.crt AddTrustExternalCARoot.crt > {{domain}}.bundle.crt
