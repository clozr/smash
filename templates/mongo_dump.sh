mongodump --username {{app_admin_user}} --password "{{app_admin_passwd}}" --authenticationDatabase admin --db $1 --out $2/$1
