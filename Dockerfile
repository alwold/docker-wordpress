FROM ubuntu:13.10
MAINTAINER John Fink <john.fink@gmail.com>
RUN apt-get update # Mon Jan 27 11:35:22 EST 2014
RUN apt-get -y upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-client mysql-server php5-fpm pwgen python-setuptools vim-tiny php5-mysql openssh-server sudo
RUN easy_install supervisor
ADD ./start.sh /start.sh
ADD ./foreground.sh /etc/apache2/foreground.sh
ADD ./supervisord.conf /etc/supervisord.conf
RUN echo %sudo	ALL=NOPASSWD: ALL >> /etc/sudoers
ADD ./wp-config-sample.php /tmp/wp-config-sample.php
RUN chmod 755 /start.sh
RUN chmod 755 /etc/apache2/foreground.sh
RUN mkdir /var/log/supervisor/
RUN mkdir /var/run/sshd
RUN mkdir -p /var/wordpress/uploads
RUN chown www-data:www-data /var/wordpress/uploads
EXPOSE 80
EXPOSE 22
CMD ["/bin/bash", "/start.sh"]
