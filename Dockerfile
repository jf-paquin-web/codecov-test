FROM php:8.0-fpm  AS codecov_test_php

RUN apt update && apt install -y --fix-missing \
    acl \
    libfcgi-bin \
    git \
    unzip \
    vim \
    nano \
    curl \
    wget \
    gnupg \
    iputils-ping \
    iproute2 \
    software-properties-common

RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

RUN apt-get update \
    && apt-get install -y libzip-dev \
    && docker-php-ext-install zip

RUN docker-php-ext-install opcache

COPY --from=composer:2.1 /usr/bin/composer /usr/local/bin/composer

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
# install Symfony Flex globally to speed up download of Composer packages (parallelized prefetching)
RUN set -eux; \
composer global require "symfony/flex" --prefer-dist --no-progress --classmap-authoritative; \
composer clear-cache
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /var/www/html

# build for production
ARG APP_ENV=prod

# prevent the reinstallation of vendors at every changes in the source code
COPY composer.json composer.lock symfony.lock ./
RUN set -eux; \
composer install --prefer-dist --no-dev --no-scripts --no-progress; \
composer clear-cache

# do not use .env files in production
COPY .env ./
RUN composer dump-env prod; \
rm .env

# copy only specifically what we need
COPY bin bin/
COPY config config/
COPY public public/
COPY src src/

RUN set -eux; \
mkdir -p var/cache var/log; \
composer dump-autoload --classmap-authoritative --no-dev; \
composer run-script --no-dev post-install-cmd; \
chmod +x bin/console; sync
VOLUME /var/www/html/var

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
COPY docker/php/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY docker/php/custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php/www.conf /usr/local/etc/php-fpm.d/www.conf

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]

# "nginx" stage
# depends on the "php" stage above
FROM nginx:1-alpine AS codecov_test_nginx

COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html/public

COPY --from=codecov_test_php /var/www/html/public ./

