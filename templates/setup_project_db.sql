DROP DATABASE IF EXISTS {{db_name}};
DROP DATABASE IF EXISTS test_{{db_name}};

CREATE DATABASE {{db_name}} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE test_{{db_name}} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON test_{{db_name}}.* TO '{{db_user}}'@'localhost';
DROP USER '{{db_user}}'@'localhost';
CREATE USER '{{db_user}}'@'localhost' IDENTIFIED BY '{{db_passwd}}';

GRANT ALL ON {{db_name}}.* TO '{{db_user}}'@'localhost';
GRANT ALL ON test_{{db_name}}.* TO '{{db_user}}'@'localhost';
FLUSH PRIVILEGES;
