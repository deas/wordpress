docker build --rm -t deas/cr-wordpress .
docker run -i -t -p 80 -e "WORDPRESS_DB_USER=wp_scratch" -e "WORDPRESS_DB_NAME=wp_scratch" -e "WORDPRESS_DB_PASSWORD=wp_scratch" deas/cr-wordpress

TODO:
_ Fix permissions
_ Take care of Jetpack debug
