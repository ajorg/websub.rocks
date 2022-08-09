FROM debian:bullseye
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update; apt-get -y install curl
RUN curl -Lf http://nginx.org/download/nginx-1.20.2.tar.gz | tar xz
RUN curl -Lf https://github.com/wandenberg/nginx-push-stream-module/archive/refs/tags/0.5.5.tar.gz | tar xz
RUN apt-get -y install gcc make libz-dev libssl-dev libpcre3-dev
RUN cd nginx-1.20.2 && \
./configure \
    --add-module=../nginx-push-stream-module-0.5.5 \
    --with-http_v2_module && \
make
RUN cd nginx-1.20.2 && make install
RUN apt-get -y install php-fpm php-curl php-mysql composer mariadb-server redis-server
RUN git clone https://github.com/ajorg/websub.rocks.git
WORKDIR websub.rocks
RUN composer install
RUN sed \
#    -e 's/websubrocks.dev/localhost/' \
    -e 's/http:\/\/websubrocks.dev/https:\/\/websubrocks.dev/' \
#    -e 's/skipauth = false/skipauth = true/' \
    -e "s/xxxx/$(head -c 15 /dev/urandom | basenc --base64url)/" \
    lib/config.template.php \
        > lib/config.php
RUN cat lib/config.php
RUN install -o mysql -d /run/mysqld
COPY create-database.sql create-database.sql
RUN mariadbd & \
sleep 5; \
mariadb < create-database.sql && \
mariadb -u root websubrocks < database/schema.sql && \
pkill -TERM mariadb && \
sleep 3
RUN install -o www-data -d /run/php
COPY nginx.conf /usr/local/nginx/conf/nginx.conf
COPY public/favicon.ico public/favicon.ico
COPY run.sh run.sh
RUN apt-get -y install vim man
EXPOSE 80/tcp
CMD ./run.sh
