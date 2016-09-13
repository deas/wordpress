# Renaming DB values from within the container
WP_DB_NAME=wp_cr_loc WP_HOME=http://brc.contentreich.de/ WP_ABSPATH=/usr/share/wordpress \
    WP_DB_USER=wp_cr_loc WP_DB_PASS=wp_cr_loc WP_DB_HOST=172.17.42.1 php ./rename_site.php


docker build --rm -t deas/cr-wordpress .

# WordPress gotcha - cannot use changing IP address in Browser
# Need hostname for now
docker run -it -P \
       --name contentreich-web.service \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_cr_loc" \
       -e "WORDPRESS_DB_NAME=wp_cr_loc" \
       -e "WORDPRESS_DB_PASSWORD=wp_cr_loc" \
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

# Gotcha! Name does not end in .service so we have short names in dnsdock !
#
# wpscratch.cr-wordpress.docker
# Not really systemd --name  %n friendly
#
docker run -it \
       --name ph \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_poptown" \
       -e "WORDPRESS_DB_NAME=wp_poptown" \
       -e "WORDPRESS_DB_PASSWORD=wp_poptown" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -e "HTTP=n" -e "HTTPS=y" \
       -v /home/deas/work/projects/contentreich/poptown-hilft:/usr/share/wordpress:rw \
       -v /var/log/apache2/poptown-hilft:/var/log/apache2 \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       deas/cr-wordpress

docker run \
       --name wpscratch \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -v /home/deas/work/projects/contentreich/wp_scratch:/usr/share/wordpress:rw \
       -v /var/log/apache2/wp_scratch:/var/log/apache2 \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       deas/cr-wordpress


# Wrong port redirects
docker run -it -P \
       --name contentreich-web1 \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_cr_loc" \
       -e "WORDPRESS_DB_NAME=wp_cr_loc" \
       -e "WORDPRESS_DB_PASSWORD=wp_cr_loc" \
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


docker run -it -P \
       --name i-am-you-web1 \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=i-am-you.de" \
       -e "WORDPRESS_DB_USER=wordpress_iau" \
       -e "WORDPRESS_DB_NAME=wordpress_iau" \
       -e "WORDPRESS_DB_PASSWORD=wordpress_iau" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -e "SERVICE_NAME=i-am-you-web1-web" \
       -e "SERVICE_TAGS=tag1,tag2" \
       -e "SERVICE_REGION=mal-guggn" \
       -v /home/deas/work/projects/contentreich/i-am-you.de:/usr/share/wordpress:rw \
       -v /var/log/apache2/i-am-you-web1:/var/log/apache2 \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       -p 8765:80 \
       deas/cr-wordpress

docker run -it \
       --name robvegas \
       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_scratch" \
       -e "WORDPRESS_DB_NAME=wp_scratch" \
       -e "WORDPRESS_DB_PASSWORD=wp_scratch" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -v /home/deas/work/projects/robvegas.de/htdocs:/usr/share/wordpress:rw \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       deas/cr-wordpress

docker run -it -d \
       --net=host \
       --name robvegas \
       -e "SMTP_DOMAIN=robvegas.de" \
       -e "WORDPRESS_DB_USER=robvegas2" \
       -e "WORDPRESS_DB_NAME=robvegas2" \
       -e "WORDPRESS_DB_PASSWORD=WeX7PXzyjXPbe7Zb" \
       -e "WORDPRESS_DB_HOST=127.0.0.1" \
       -v /local/sites/www.robvegas.de/htdocs:/usr/share/wordpress:rw \
       -v /etc/localtime:/etc/localtime:ro \
       -v /run/systemd/journal/dev-log:/dev/log \
       deas/cr-wordpress


www.digiheads.de
digihea-brc:9876


digiheads.de
brc-dig:9876

i-am-you.de
br-iau:8765

export WP_DB_HOST=172.17.42.1
export WP_DB_PASS=wp_digih
export WP_DB_USER=wp_digih
export WP_DB_NAME=wp_digih
export WP_HOME=http://brc-dig:9876
export WP_ABSPATH=/usr/share/wordpress

php /rename.site.php




# TODO: works, execept that we don't have a replacement for --add-host yet
docker service create --replicas 1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_cr_loc" \
       -e "WORDPRESS_DB_NAME=wp_cr_loc" \
       -e "WORDPRESS_DB_PASSWORD=wp_cr_loc" \
       -e "WORDPRESS_JETPACK_DEV_DEBUG=1" \
       -e "PHP_XDEBUG_ENABLED=1" \
       -e "SERVICE_NAME=contentreich-web" \
       -e "SERVICE_TAGS=tag1,tag2" \
       -e "SERVICE_REGION=mal-guggn" \
       -e "WWW_UID=1000" \
       -e "WWW_GID=1000" \
       --mount type=bind,src=/home/deas/work/projects/contentreich/contentreich-wordpress,dst=/usr/share/wordpress \
       --mount type=bind,src=/var/log/apache2/contentreich-web1,dst=/var/log/apache2 \
       --mount type=bind,src=/etc/localtime,dst=/etc/localtime,readonly \
       --mount type=bind,src=/run/systemd/journal/dev-log,dst=/dev/log \
       -p 80:80 \
       --name contentreich-web \
       deas/cr-wordpress

# ping docker.com

       --add-host=smtp:172.17.42.1 \
       -e "SMTP_DOMAIN=contentreich.de" \
       -e "WORDPRESS_DB_USER=wp_cr_loc" \
       -e "WORDPRESS_DB_NAME=wp_cr_loc" \
       -e "WORDPRESS_DB_PASSWORD=wp_cr_loc" \
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
