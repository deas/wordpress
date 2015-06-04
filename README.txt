docker build --rm -t deas/cr-wordpress .

# Wrong port redirects
docker run -it -P \
       --name contentreich-web1 \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "SERVICE_NAME=contentreich-web" \
       -e "SERVICE_TAGS=tag1,tag2" \
       -e "SERVICE_REGION=mal-guggn" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "IMPORT_SRC=/usr/share/wordpress-import/" \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       -v /home/deas/tmp/wp-import/:/usr/share/wordpress-import:ro \
       deas/cr-wordpress

# WORDPRESS_HOME value runs renaming
#       -e "WORDPRESS_HOME=http://brc.contentreich.de/" \


docker run -it -P \
       --name contentreich-web1 \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -e "SERVICE_NAME=contentreich-web" \
       -e "SERVICE_TAGS=tag1,tag2" \
       -e "SERVICE_REGION=mal-guggn" \
       -v /home/deas/work/projects/contentreich/contentreich-wordpress:/usr/share/wordpress:rw \
       -v /var/log/apache2/contentreich-web1:/var/log/apache2 \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       deas/cr-wordpress
TODO:
_ Fix permissions -> Must be data container or external


docker run -it -P \
       --name digiheads-web1 \
       --add-host=smtp:172.17.42.1 \
       -e "WORDPRESS_HOME=http://digihea-brc:9876/" \
       -e "WORDPRESS_DB_USER=wp_digih" \
       -e "WORDPRESS_DB_NAME=wp_digih" \
       -e "WORDPRESS_DB_PASSWORD=wp_digih" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -v /home/deas/work/projects/digiheads/digiheads.de:/usr/share/wordpress:rw \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       -p 9876:80 \
       deas/cr-wordpress


www.digiheads.de
digihea-brc:9876


digiheads.de
brc-dig:9876

export WP_DB_HOST=172.17.42.1
export WP_DB_PASS=wp_digih
export WP_DB_USER=wp_digih
export WP_DB_NAME=wp_digih
export WP_HOME=http://brc-dig:9876
export WP_ABSPATH=/usr/share/wordpress

php /rename.site.php
