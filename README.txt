docker build --rm -t deas/cr-wordpress .

# Wrong port redirects
docker run -it -P \
       --name contentreich-web1 \
       -e "WORDPRESS_HOME=http://brc.contentreich.de/" \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "SERVICE_NAME=contentreich-web" \
       -e "SERVICE_TAGS=tag1,tag2" \
       -e "SERVICE_REGION=mal-guggn" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "IMPORT_SRC=/usr/share/wordpress-import/" \
       -v /etc/localtime:/etc/localtime:ro \
       -v /home/deas/tmp/wp-import/:/usr/share/wordpress-import:ro \
       deas/cr-wordpress

docker run -it -P \
       --name contentreich-web1 \
       -e "WORDPRESS_HOME=http://brc.contentreich.de/" \
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
       deas/cr-wordpress
TODO:
_ Fix permissions -> Must be data container or external
