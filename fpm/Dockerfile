FROM php:7.0-fpm
ENV LANG C

# install the PHP extensions we need
# curl
#
# And pagespeed, although we disable it
# https://developers.google.com/speed/pagespeed/module/download
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev wget ssmtp  \
        && rm -rf /var/lib/apt/lists/* \
        && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
        && docker-php-ext-install gd mysqli opcache \
        && wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /wp && chmod 755 /wp

RUN mkdir ~/software \
    && cd  ~/software/ \
    && wget http://xdebug.org/files/xdebug-2.5.0.tgz \
    && tar -xvzf xdebug-2.5.0.tgz \
    && cd xdebug-2.5.0 \
    && phpize \
    && ./configure \
    && make \
    && cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012 \
    && echo "zend_extension = /usr/local/lib/php/extensions/no-debug-non-zts-20151012/xdebug.so" >>  /usr/local/etc/php/php.ini \
    && cd ~ && rm -rf software

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
# ADD ../ does not work
ADD wp-config-template.php /wp-config-template.php
ADD docker-entrypoint.sh /entrypoint.sh
ADD execute-statements-mysql.php  /execute-statements-mysql.php
ADD rename_site.php /rename_site.php
# http adds dont cache
# ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar  /wp
# ADD wp-cli.phar  /wp

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
# CMD ["apache2", "-DFOREGROUND"]
# EXPOSE 9000
CMD ["php-fpm"]
