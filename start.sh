#!/bin/bash
if [ ! -f /var/www/wp-config.php ]; then
#let's create a user to ssh into
SSH_USERPASS=`pwgen -c -n -1 8`
mkdir /home/user
useradd -G sudo -d /home/user user
chown user /home/user
echo user:$SSH_USERPASS | chpasswd
echo ssh user password: $SSH_USERPASS
#mysql has to be started this way as it doesn't work to call from /etc/init.d
/usr/bin/mysqld_safe & 
sleep 10s
# Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
WORDPRESS_DB="wordpress"
MYSQL_PASSWORD=`pwgen -c -n -1 12`
WORDPRESS_PASSWORD=`pwgen -c -n -1 12`
#This is so the passwords show up in logs. 
echo mysql root password: $MYSQL_PASSWORD
echo wordpress password: $WORDPRESS_PASSWORD
echo $MYSQL_PASSWORD > /mysql-root-pw.txt
echo $WORDPRESS_PASSWORD > /wordpress-db-pw.txt
#there used to be a huge ugly line of sed and cat and pipe and stuff below,
#but thanks to @djfiander's thing at https://gist.github.com/djfiander/6141138
#there isn't now.

sed -e "s/database_name_here/$WORDPRESS_DB/
s/username_here/$WORDPRESS_DB/
s/password_here/$WORDPRESS_PASSWORD/
/'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
/'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /tmp/wp-config-sample.php > /etc/wp-config.php

sed -e "s/^listen = .*$/listen = 9000/" /etc/php5/fpm/pool.d/www.conf > /etc/php5/fpm/pool.d/www.conf.new
mv /etc/php5/fpm/pool.d/www.conf.new /etc/php5/fpm/pool.d/www.conf

# fix this: http://gaijin-nippon.blogspot.com/2013/07/audit-on-lxc-host.html
sed -i "s/^session\s\s*required\s\s*pam_loginuid\.so/#&/" /etc/pam.d/sshd

mysqladmin -u root password $MYSQL_PASSWORD 
mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY '$WORDPRESS_PASSWORD'; FLUSH PRIVILEGES;"
killall mysqld
sleep 10s
fi
supervisord -n
