#!/bin/sh

echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
echo "http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
apk --update add bash bc curl git jq nano msmtp s6 sudo zip \
  letsencrypt \
  libmemcached \
  mariadb-client \
  nginx-naxsi \
  php-cli \
  php-curl \
  php-ctype \
  php-dom \
  php-fpm \
  php-gd \
  php-gettext \
  php-iconv \
  php-json \
  php-mcrypt \
  php-memcache \
  php-mysqli \
  php-mysql \
  php-opcache \
  php-openssl \
  php-phar \
  php-pear \
  php-soap \
  php-xml \
  php-zlib \
  php-zip

# COMPOSER
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# PREDIS
pear channel-discover pear.nrk.io
pear install nrk/Predis

# WP-CLI
curl -sL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /usr/local/bin/wp
chmod +x /usr/local/bin/wp

# DIG
curl -sL https://github.com/sequenceiq/docker-alpine-dig/releases/download/v9.10.2/dig.tgz|tar -xzv -C /usr/local/bin/

# MSMTP
cat /wps/etc/msmtprc > /etc/msmtprc
echo "sendmail_path = /usr/bin/msmtp -t" > /etc/php/conf.d/sendmail.ini

# SUBMARINE
ln -s /wps/bin/run.sh /usr/bin/wps
adduser -D -G nginx -s /bin/sh -u 1000 -h /submarine submarine
echo "submarine ALL = NOPASSWD : ALL" >> /etc/sudoers
