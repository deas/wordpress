#!/bin/bash
# defroute=`ip route show | grep ^default`
# routeparts=(${defroute//;/ })
# hostip=${routeparts[2]}
# hostif=${routeparts[4]}

EXTRACT_DIR=..
SRC_DIR=/

#  Test overwrites
# . test_env.sh
# : ${WORDPRESS_JETPACK_DEV_DEBUG:=1}
WORDPRESS_JETPACK_DEV_DEBUG=${WORDPRESS_JETPACK_DEV_DEBUG-"1"}
IMPORT_SRC=${IMPORT_SRC-"/usr/share/wordpress-import"}
IMPORT_SQL=${IMPORT_SRC}/wordpress.sql

set -e

if [ -z "$MYSQL_PORT_3306_TCP" ]; then
#	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
#	echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
#	exit 1
    # Host/testing tweak
    if ip -B link show docker0 >/dev/null 2>&1 ; then
        WORDPRESS_DB_HOST=localhost
    else
        WORDPRESS_DB_HOST=`ip route show | grep ^default | awk '{print $3}'`
    fi
else
    WORDPRESS_DB_HOST="${MYSQL_PORT_3306_TCP#tcp://}"
fi

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	echo >&2 'error: missing required WORDPRESS_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e WORDPRESS_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be WORDPRESS_DB_USER and WORDPRESS_DB_NAME.)'
	exit 1
fi

# Set up the installation if wordpress is not there
if ! [ -e "${EXTRACT_DIR}/wordpress/index.php" -a -e "${EXTRACT_DIR}/wordpress/wp-includes/version.php" ]; then
    echo >&2 "WordPress not found in ${EXTRACT_DIR}/wordpress - copying now..."
    if [ -d "${EXTRACT_DIR}/wordpress" ] && [ "$(ls -A ${EXTRACT_DIR}/wordpress)" ]; then
	echo >&2 "WARNING: ${EXTRACT_DIR}/wordpress is not empty - press Ctrl+C now if this is an error!"
	( set -x; ls -A ${EXTRACT_DIR}/wordpress ; sleep 10 )
    fi
    if [ -e "${IMPORT_SRC}/wp-includes/version.php" ] ; then
        rsync --archive --one-file-system --quiet "$IMPORT_SRC" "${EXTRACT_DIR}/wordpress"
        if [ -e "${IMPORT_SQL}" ] ; then
            cat "${IMPORT_SQL}" | TERM=dumb php "${SRC_DIR}/execute-statements-mysql.php" $WORDPRESS_DB_HOST $WORDPRESS_DB_NAME $WORDPRESS_DB_USER $WORDPRESS_DB_PASSWORD
        fi
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar "${EXTRACT_DIR}/wordpress/wp"

        # FIXME : change hostname/home when its given
        mv ${EXTRACT_DIR}/wordpress/index.php ${EXTRACT_DIR}/wordpress/index.php-orig
        mv ${SRC_DIR}/rename.site.php ${EXTRACT_DIR}/wordpress/index.php
    else
        current=$(curl -sSL 'http://api.wordpress.org/core/version-check/1.7/' | sed -r 's/^.*"current":"([^"]+)".*$/\1/')
        curl -SL http://wordpress.org/wordpress-$current.tar.gz | tar -xzC ${EXTRACT_DIR}
    fi
    cp "${SRC_DIR}/wp-config-template.php" "${EXTRACT_DIR}/wordpress/wp-config.php"
    # rsync --archive --one-file-system --quiet /usr/share/wordpress/ ./
    echo >&2 "Complete! WordPress has been successfully set up"
#       BULLETPROOF writes this file
# 	if [ ! -e .htaccess ]; then
# 		cat > .htaccess <<-'EOF'
# 			RewriteEngine On
# 			RewriteBase /
# 			RewriteRule ^index\.php$ - [L]
# 			RewriteCond %{REQUEST_FILENAME} !-f
# 			RewriteCond %{REQUEST_FILENAME} !-d
# 			RewriteRule . /index.php [L]
# 		EOF
# 	fi
fi

# TODO handle WordPress upgrades magically in the same way, but only if wp-includes/version.php's $wp_version is less than /usr/share/wordpress/wp-includes/version.php's $wp_version

# if [ ! -e wp-config.php ]; then
# 	awk '/^\/\*.*stop editing.*\*\/$/ && c == 0 { c = 1; system("cat") } { print }' wp-config-sample.php > wp-config.php <<'EOPHP'
# // If we're behind a proxy server and using HTTPS, we need to alert Wordpress of that fact
# // see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
# if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
# 	$_SERVER['HTTPS'] = 'on';
# }
#
# EOPHP
# fi

set_config() {
	key="$1"
	value="$2"
	php_escaped_value="$(php -r 'var_export($argv[1]);' "$value")"
	sed_escaped_value="$(echo "$php_escaped_value" | sed 's/[\/&]/\\&/g')"
	sed -ri "s/((['\"])$key\2\s*,\s*)(['\"]).*\3/\1$sed_escaped_value/" "${EXTRACT_DIR}/wordpress/wp-config.php"
}

set_apache_config() {
    key="$1"
    value="$2"
    sed -ri "s/(SetEnv $key) .*/\1 $value/" /etc/apache2/sites-enabled/wordpress.conf
}

if [ -w /etc/apache2/sites-enabled/wordpress.conf ] ; then
    set_apache_config 'WP_JETPACK_DEV_DEBUG'_"$WORDPRESS_JETPACK_DEV_DEBUG"
    set_apache_config 'WP_DB_HOST' "$WORDPRESS_DB_HOST"
    set_apache_config 'WP_DB_USER' "$WORDPRESS_DB_USER"
    set_apache_config 'WP_DB_PASS' "$WORDPRESS_DB_PASSWORD"
    set_apache_config 'WP_DB_NAME' "$WORDPRESS_DB_NAME"
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
for unique in "${UNIQUES[@]}"; do
	eval unique_value=\$WORDPRESS_$unique
	if [ "$unique_value" ]; then
		set_config "$unique" "$unique_value"
	else
		# if not specified, let's generate a random value
		set_config "$unique" "$(head -c1M /dev/urandom | sha1sum | cut -d' ' -f1)"
	fi
done

if [ -n "$APACHE_RUN_USER" -a -n "$APACHE_RUN_GROUP" ] ; then
    chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" .
fi

exec "$@"
