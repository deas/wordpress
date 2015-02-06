FROM ubuntu:trusty

RUN apt-get update && apt-get install -y apache2 apache2-utils curl libapache2-mod-php5 php5-curl php5-gd \
    php5-mysql php5-xdebug rsync wget && rm -rf /var/lib/apt/lists/*
RUN a2enmod rewrite

# copy a few things from apache's init script that it requires to be setup
ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars
# and then a few more from $APACHE_CONFDIR/envvars itself
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_PID_FILE $APACHE_RUN_DIR/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_LOG_DIR /var/log/apache2
ENV LANG C
RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

# make CustomLog (access log) go to stdout instead of files, ErrorLog to stderr
RUN find "$APACHE_CONFDIR" -type f -exec sed -ri ' \
    s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
    s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
' '{}' ';'

# We can use multiple entries!
# The filename for the access log is relative to the ServerRoot unless it begins with a slash.
# ErrorLog "|/usr/bin/rotatelogs -l /var/log/apache2/.../error-%Y.%m.%d.log 86400"
# CustomLog "|/usr/bin/rotatelogs -l /var/log/apache2/.../access-%Y.%m.%d.log 86400" common

# RUN rm -rf /var/www/html && mkdir /var/www/html
# VOLUME /var/www/html
VOLUME /usr/share/wordpress
VOLUME /var/log/www
WORKDIR /usr/share/wordpress

ADD docker-apache.conf /etc/apache2/sites-available/wordpress.conf
RUN a2dissite 000-default && a2ensite wordpress
ADD wp-config-template.php /wp-config-template.php
ADD docker-entrypoint.sh /entrypoint.sh
ADD execute-statements-mysql.php  /execute-statements-mysql.php
ADD rename_site.php /rename.site.php
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  /wp
RUN chmod 755 /wp

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80
CMD ["apache2", "-DFOREGROUND"]
