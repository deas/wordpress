FROM php:7.0-apache

# copy a few things from apache's init script that it requires to be setup
ENV LANG C.UTF-8
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

# install the PHP extensions we need
# curl
#
# And pagespeed, although we disable it
# https://developers.google.com/speed/pagespeed/module/download
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev wget ssmtp openssl \
        && rm -rf /var/lib/apt/lists/* \
        && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd mysqli opcache \
        && a2enmod rewrite && a2enmod ssl && a2enmod headers && a2enmod expires \
        && a2enconf security \
        && sed -i 's/^ServerSignature/#ServerSignature/g' /etc/apache2/conf-enabled/security.conf \
        && sed -i 's/^ServerTokens/#ServerTokens/g' /etc/apache2/conf-enabled/security.conf \
        && echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf \
        && echo "ServerTokens Prod" >> /etc/apache2/conf-enabled/security.conf \
        && wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /wp && chmod 755 /wp \
        && wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb && dpkg -i mod-pagespeed-stable_current_amd64.deb && rm mod-pagespeed-stable_current_amd64.deb \
        && echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf \
        && mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR \
        && mkdir -p ${APACHE_CONFDIR}/external

RUN mkdir ~/software && \
    && cd  ~/software/ \
    && wget http://xdebug.org/files/xdebug-2.4.0.tgz \
    && tar -xvzf xdebug-2.4.0.tgz \
    && cd xdebug-2.4.0 \
    && phpize \
    && ./configure \
    && make \
    && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012 \
    && echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so" >>  /usr/local/etc/php/php.ini \
    && cd ~ && rm -rf software \
    && a2dismod pagespeed

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Most frequent changing stuff last
ADD docker-apache.conf /etc/apache2/sites-available/wordpress.conf
ADD docker-apache-ssl.conf /etc/apache2/sites-available/wordpress-ssl.conf
ADD wp-config-template.php /wp-config-template.php
ADD docker-entrypoint.sh /entrypoint.sh
ADD execute-statements-mysql.php  /execute-statements-mysql.php
ADD rename_site.php /rename_site.php
# http adds dont cache
# ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  /wp
# ADD wp-cli.phar  /wp

RUN a2dissite 000-default
# && a2ensite wordpress && a2ensite wordpress-ssl

#    && \
#    find "$APACHE_CONFDIR" -type f -exec sed -ri ' \
#    s!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g; \
#    s!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g; \
#    ' '{}' ';'

# a2dissite 000-default && a2ensite wordpress && chmod 755 /wp
# sendmail

# The filename for the access log is relative to the ServerRoot unless it begins with a slash.
# ErrorLog "|/usr/bin/rotatelogs -l /var/log/apache2/.../error-%Y.%m.%d.log 86400"
# CustomLog "|/usr/bin/rotatelogs -l /var/log/apache2/.../access-%Y.%m.%d.log 86400" common

# RUN rm -rf /var/www/html && mkdir /var/www/html
# VOLUME /var/www/html
VOLUME /usr/share/wordpress
VOLUME /var/log/www
WORKDIR /usr/share/wordpress

### RUN a2dissite 000-default && a2ensite wordpress && chmod 755 /wp

ENTRYPOINT ["/entrypoint.sh"]
# We use --expose 80 at runtime
# No way to get rid of EXPOSE setting from here
# EXPOSE 80
# FIXME two ports do not yet play with docker-discover
#    server bruce:contentreich-web.service:443 172.17.0.24:443 check inter 2s rise 3 fall 2
#    server bruce:contentreich-web.service:80 172.17.0.24:80 check inter 2s rise 3 fall 2
# EXPOSE 443
CMD ["apache2", "-DFOREGROUND"]
