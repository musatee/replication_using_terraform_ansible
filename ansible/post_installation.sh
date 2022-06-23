#!/bin/bash 
DBHOST="${1}"
DBNAME="${2}"
DBUSER="${3}" 
DBPASS="${4}" 
WORKDIR="${5}" 

cd "${WORKDIR}" && cp .env.example .env 
sed -i "s#^APP_DEBUG=.*#APP_DEBUG=false#; s#^DB_CONNECTION=.*#DB_CONNECTION=mysql#; s#^DB_HOST=.*#DB_HOST=${DBHOST}#; s#^DB_DATABASE=.*#DB_DATABASE=${DBNAME}#; s#^DB_USERNAME=.*#DB_USERNAME=${DBUSER}#;s#^DB_PASSWORD=.*#DB_PASSWORD=${DBPASS}#" .env 
if [[ "${?}" -eq 0 ]] 
then 
    composer update --no-interaction 
    composer install --no-interaction
    php artisan key:generate --force 
    php artisan config:cache
    php artisan migrate:refresh --force
    chown -R www-data:www-data . 
    exit 0 
else 
    exit 1 
fi

