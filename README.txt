docker build --rm -t deas/cr-wordpress .

# Wrong port redirects
docker run -i -t -p 1080:80 \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "IMPORT_SRC=/usr/share/wordpress-import/" \
       -v /etc/localtime:/etc/localtime:ro \
       -v /home/deas/tmp/wp-import/:/usr/share/wordpress-import:ro \
       deas/cr-wordpress

docker run -i -t -p 1080:80 \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -v /etc/localtime:/etc/localtime:ro \
       deas/cr-wordpress
TODO:
_ Fix permissions -> Must be data container or external
