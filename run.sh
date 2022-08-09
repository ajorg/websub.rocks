#!/bin/bash
/usr/local/nginx/sbin/nginx
/usr/sbin/php-fpm7.4
/usr/sbin/mariadbd &
/usr/bin/redis-server &
wait -n
