#!/bin/sh
set -e

# For supporting host.docker.internal on Linux. See https://github.com/docker/for-linux/issues/264
if ! ping -c1 host.docker.internal 1>/dev/null 2>/dev/null
then
    ip -4 route list match 0/0 | awk '{print $3 " host.docker.internal"}' >> /etc/hosts
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [ -n "$NR_INSTALL_KEY" ]; then
  echo "Installing newrelic"
  NR_INSTALL_SILENT=1 newrelic-install install
  sed -i \
      -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$NR_APP_NAME\"/" \
      -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
      -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
      -e 's/;newrelic.distributed_tracing_enabled =.*/newrelic.distributed_tracing_enabled = true/' \
      /usr/local/etc/php/conf.d/newrelic.ini
fi

PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
if [ "$APP_ENV" != 'prod' ]; then
  PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
fi
ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

mkdir -p var/cache var/log
setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var
setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var

if [ "$APP_ENV" != 'prod' ]; then
  XDEBUG_MODE=off composer install --prefer-dist --no-progress --no-interaction
fi

exec docker-php-entrypoint "php-fpm"
