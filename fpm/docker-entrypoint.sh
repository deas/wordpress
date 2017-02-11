#!/bin/bash
# defroute=`ip route show | grep ^default`
# routeparts=(${defroute//;/ })
# hostip=${routeparts[2]}
# hostif=${routeparts[4]}
#
# FIXME: wp-config.php should
#
WORDPRESS_ABSPATH=`pwd`
EXTRACT_DIR=..
SRC_DIR=/

#  Test overwrites
# . test_env.sh
# : ${WORDPRESS_JETPACK_DEV_DEBUG:=1}
WORDPRESS_JETPACK_DEV_DEBUG=${WORDPRESS_JETPACK_DEV_DEBUG-"1"}
WORDPRESS_DEBUG=${WORDPRESS_DEBUG-"0"}
WORDPRESS_DEBUG_LOG=${WORDPRESS_DEBUG_LOG-"0"}
WORDPRESS_DEBUG_DISPLAY=${WORDPRESS_DEBUG_DISPLAY-"0"}
WORDPRESS_SCRIPT_DEBUG=${WORDPRESS_SCRIPT_DEBUG-"0"}
WORDPRESS_SAVEQUERIES=${WORDPRESS_SAVEQUERIES-"0"}
PHP_XDEBUG_ENABLED=${PHP_XDEBUG_ENABLED-"0"}
IMPORT_SRC=${IMPORT_SRC-"/usr/share/wordpress-import"}
IMPORT_SQL=${IMPORT_SRC}/wordpress.sql
DOCKER_HOST=`ip route show | grep ^default | awk '{print $3}'`
SMTP_HOST=`{ grep smtp /etc/hosts || echo $DOCKER_HOST; } |  sed -e s,"\s.*",,g`
SMTP_DOMAIN=${SMTP_DOMAIN-"localhost"}
HTTP=${HTTP-"y"}
HTTPS=${HTTPS-"n"}

set -xe

# function print_help {
#     cat <<EOF
# Usage $0
# Download and setup alfresco
#   -v                  Alfresco version, e.g. "4.2.f"
#   -h                  This help
# EOF
# }

# FIXME - We should really move more (but not all swiches to commandline args)
# Not quite, will be clumsy to override command from the cli
# while getopts "hH:S:" opt; do
#     case "$opt" in
#         H) HTTP=$OPTARG ;;
#         S) HTTPS=$OPTARG ;;
#         # h) print_help;exit 2 ;;
#     esac
# done


if [ -z "$MYSQL_PORT_3306_TCP" ]; then
    # echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
    # echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
    # exit 1
    # Host/testing tweak
    if ip -B link show docker0 >/dev/null 2>&1 ; then
        WORDPRESS_DB_HOST=localhost
    else
        WORDPRESS_DB_HOST="$DOCKER_HOST"
    fi
else
    WORDPRESS_DB_HOST="${MYSQL_PORT_3306_TCP#tcp://}"
fi

printenv
echo

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
    echo >&2 'error: missing required WORDPRESS_DB_PASSWORD environment variable'
    echo >&2 '  Did you forget to -e WORDPRESS_DB_PASSWORD=... ?'
    echo >&2
    echo >&2 '  (Also of interest might be WORDPRESS_DB_USER and WORDPRESS_DB_NAME.)'
    exit 1
fi

# Set up the installation if wordpress is not there
if ! [ -e "${EXTRACT_DIR}/wordpress/index.php" -a -e "${EXTRACT_DIR}/wordpress/wp-includes/version.php" ]; then
    echo >&2 "WordPress not found in ${EXTRACT_DIR}/wordpress"
    current=$(curl -sSL 'http://api.wordpress.org/core/version-check/1.7/' | sed -r 's/^.*"current":"([^"]+)".*$/\1/')
    echo "Initializing vanilla Wordpress $current"
    curl -SL http://wordpress.org/wordpress-$current.tar.gz | tar -xzC ${EXTRACT_DIR}
#    cp "${SRC_DIR}/wp-config-template.php" "${EXTRACT_DIR}/wordpress/wp-config.php"
    echo >&2 "Complete! WordPress has been successfully set up"
elif [ -e "${IMPORT_SQL}" ] ; then
    echo "Importing SQL"
    cat "${IMPORT_SQL}" | TERM=dumb php "${SRC_DIR}/execute-statements-mysql.php" $WORDPRESS_DB_HOST $WORDPRESS_DB_NAME $WORDPRESS_DB_USER $WORDPRESS_DB_PASSWORD
    if ! [ -z "$WORDPRESS_HOME" ] ; then
        echo "Fixing values in database"
        WP_DB_NAME="$WORDPRESS_DB_NAME" WP_HOME="$WORDPRESS_HOME" WP_ABSPATH="$WORDPRESS_ABSPATH" \
                  WP_DB_USER="$WORDPRESS_DB_USER" WP_DB_PASS="$WORDPRESS_DB_PASSWORD" WP_DB_HOST="$WORDPRESS_DB_HOST" php ${SRC_DIR}/rename.site.php
    fi
fi

if ! [ -e "${EXTRACT_DIR}/wordpress/wp-config.php" ] ; then
    cp "${SRC_DIR}/wp-config-template.php" "${EXTRACT_DIR}/wordpress/wp-config.php"
fi

#        BULLETPROOF writes this file
#        if [ ! -e .htaccess ]; then
#            cat > .htaccess <<-'EOF'
# RewriteEngine On
# RewriteBase /
# RewriteRule ^index\.php$ - [L]
# RewriteCond %{REQUEST_FILENAME} !-f
# RewriteCond %{REQUEST_FILENAME} !-d
# RewriteRule . /index.php [L]
# EOF
#        fi

# TODO handle WordPress upgrades magically in the same way, but only if wp-includes/version.php's $wp_version is less
# than /usr/share/wordpress/wp-includes/version.php's $wp_version

set_config() {
    key="$1"
    value="$2"
    php_escaped_value="$(php -r 'var_export($argv[1]);' "$value")"
    sed_escaped_value="$(echo "$php_escaped_value" | sed 's/[\/&]/\\&/g')"
    sed -ri "s/((['\"])$key\2\s*,\s*)(['\"]).*\3/\1$sed_escaped_value/" "${EXTRACT_DIR}/wordpress/wp-config.php"
}

# set_apache_config() {
#     key="$1"
#     value="$2"
#     sed -ri "s/(SetEnv $key) .*/\1 $value/" /etc/apache2/sites-available/wordpress.conf
#     sed -ri "s/(SetEnv $key) .*/\1 $value/" /etc/apache2/sites-available/wordpress-ssl.conf
# }

# set_php_config() {
#     key="$1"
#     value="$2"
#     sed -ri "s/($key) *=.*/\1 = $value/" /etc/php5/apache2/php.ini
# }

# set_php_config 'SMTP' "$WORDPRESS_SMTP_HOST"

# # FIXME : We might wan't to use wordpress.conf from  docroot during development for convenience
# # No we will implement decent external config pull in
# # if [ -w /etc/apache2/sites-enabled/wordpress.conf ] ; then
# echo "Setting up apache virtual host"
# set_apache_config 'WP_JETPACK_DEV_DEBUG' "$WORDPRESS_JETPACK_DEV_DEBUG"
# set_apache_config 'WP_DEBUG' "$WORDPRESS_DEBUG"
# set_apache_config 'WP_DEBUG_LOG' "$WORDPRESS_DEBUG_LOG"
# set_apache_config 'WP_DEBUG_DISPLAY' "$WORDPRESS_DEBUG_DISPLAY"
# set_apache_config 'SCRIPT_DEBUG' "$WORDPRESS_SCRIPT_DEBUG"
# set_apache_config 'SAVEQUERIES' "$WORDPRESS_SAVEQUERIES"
# set_apache_config 'WP_DB_HOST' "$WORDPRESS_DB_HOST"
# set_apache_config 'WP_DB_USER' "$WORDPRESS_DB_USER"
# set_apache_config 'WP_DB_PASS' "$WORDPRESS_DB_PASSWORD"
# set_apache_config 'WP_DB_NAME' "$WORDPRESS_DB_NAME"
# #    set_apache_config 'WP_ABSPATH' "$WORDPRESS_ABSPATH"
# # fi

# xdebug-2.4.0 supports PHP7 (boom!)
if grep xdebug.so /usr/local/etc/php/php.ini >/dev/null ; then
    echo "Setting up xdebug.ini"
    cat > /usr/local/etc/php/conf.d/xdebug.ini <<EOF
xdebug.remote_enable=$PHP_XDEBUG_ENABLED
xdebug.remote_autostart=0
; xdebug.remote_connect_back=0
; does not work with docker services
xdebug.remote_connect_back=0
xdebug.remote_port=9000
xdebug.remote_host=$DOCKER_HOST
xdebug.remote_log=/tmp/php-xdebug.log
EOF
fi

# allow any of these "Authentication Unique Keys and Salts." to be specified via
# environment variables with a "WORDPRESS_" prefix (ie, "WORDPRESS_AUTH_KEY")
UNIQUES=(
    AUTH_KEY
    SECURE_AUTH_KEY
    LOGGED_IN_KEY
    NONCE_KEY
    AUTH_SALT
    SECURE_AUTH_SALT
    LOGGED_IN_SALT
    NONCE_SALT
)

echo "Setting values wp-config.php"

for unique in "${UNIQUES[@]}"; do
    eval unique_value=\$WORDPRESS_$unique
    if [ "$unique_value" ]; then
        set_config "$unique" "$unique_value"
    else
        # if not specified, let's generate a random value
        set_config "$unique" "$(head -c1M /dev/urandom | sha1sum | cut -d' ' -f1)"
    fi
done

# if [ -n "$APACHE_CHOWN_USER" -a -n "$APACHE_CHOWN_GROUP" ] ; then
#     echo "Setting ownership in document root"
#     chown -R "$APACHE_CHOWN_USER:$APACHE_CHOWN_GROUP" .
# fi

echo "Setting up ssmtp.conf"
sed -i -e 's/.*mailhub=.*l/mailhub=smtp/' -e '/hostname=/d' -e "s/.*rewriteDomain=.*/rewriteDomain=$SMTP_DOMAIN/" /etc/ssmtp/ssmtp.conf
#     -e 's/#rewriteDomain=/rewriteDomain=ourdomain/' \
#     -e '/hostname=/d' \
#     /etc/ssmtp/ssmtp.conf

# https://issues.apache.org/bugzilla/show_bug.cgi?id=54519
# rm -f "${APACHE_PID_FILE}"
# rm -f /var/run/apache2/apache2.pid


# # From https://github.com/MarvAmBass/docker-apache2-ssl-secure
# if [ ! -z ${HSTS_HEADERS_ENABLE+x} ]
# then
#   echo ">> HSTS Headers enabled"
#   sed -i 's/#Header add Strict-Transport-Security/Header add Strict-Transport-Security/g' /etc/apache2/sites-enabled/001-default-ssl
#
#   if [ ! -z ${HSTS_HEADERS_ENABLE_NO_SUBDOMAINS+x} ]
#   then
#     echo ">> HSTS Headers configured without includeSubdomains"
#     sed -i 's/; includeSubdomains//g' /etc/apache2/sites-enabled/001-default-ssl
#   fi
# else
#   echo ">> HSTS Headers disabled"
# fi
#
# if [ ! -e "/etc/apache2/external/cert.pem" ] || [ ! -e "/etc/apache2/external/key.pem" ]
# then
#   echo ">> generating self signed cert"
#   openssl req -x509 -newkey rsa:4086 \
#   -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=localhost" \
#   -keyout "/etc/apache2/external/key.pem" \
#   -out "/etc/apache2/external/cert.pem" \
#   -days 3650 -nodes -sha256
# fi
#
# if stat -t ${APACHE_CONFDIR}/external/*.conf >/dev/null 2>&1
# then
#     cp ${APACHE_CONFDIR}/external/*.conf ${APACHE_CONFDIR}/sites-enabled/
# else
#     echo "Got no external configuration"
# fi
#
# if [ ${HTTP} == "y" ] ; then
#     a2ensite wordpress
# fi
# if [ ${HTTPS} == "y" ] ; then
#     a2ensite wordpress-ssl
# fi

# Dev goodness
if [ -n "${WWW_UID}" ] ; then
    usermod -u ${WWW_UID} www-data
fi

if [ -n "${WWW_GID}" ] ; then
    groupmod -g ${WWW_GID} www-data
fi

# echo ">> exec docker CMD"
# echo "$@"
exec "$@"
