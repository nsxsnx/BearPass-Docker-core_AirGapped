#!/bin/bash

set -e

echo "Initializing"

USERNAME="www-data"
GROUPNAME="www-data"

LUID=${USER_ID:-0}
LGID=${GROUP_ID:-0}

if [ $LUID -eq 0 ]; then
    LUID=65534
fi

if [ $LGID -eq 0 ]; then
    LGID=65534
fi

groupadd -o -g $LGID $GROUPNAME >/dev/null 2>&1 ||
groupmod -o -g $LGID $GROUPNAME >/dev/null 2>&1
useradd -o -u $LUID -g $GROUPNAME -s /bin/false $USERNAME >/dev/null 2>&1 ||
usermod -o -u $LUID -g $GROUPNAME -s /bin/false $USERNAME >/dev/null 2>&1
mkhomedir_helper $USERNAME

vendor_dir=/var/www/bearpass_deps/vendor/
echo "Moving pre-installed vendor dependencies to app directory..."
test -d "$vendor_dir" && mv -f "$vendor_dir" /var/www/bearpass/vendor/

echo "Updating autoload..."
cd /var/www/bearpass/ && \
composer dump-autoload

if [ ! -f "/var/www/bearpass/.env" ]
then
    echo "Configuring, initialising / updating database..."
    cd /var/www/bearpass && \
    cp .env.example .env && \
    php artisan key:generate && \
    php artisan encryption-key:generate && \
    php artisan migrate --seed --no-interaction --force && \
    php artisan optimize:clear
fi

chown -R $USERNAME:$GROUPNAME /var/www/bearpass

echo "Starting"

exec "$@"
