#!/bin/bash 

# install composer 
if [[ -e $(which php) ]]
then 
    curl -sS https://getcomposer.org/installer | php 
    if [[ "${?}" -eq 0 ]] 
    then
        mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer 
        exit 0
    fi
else 
    echo "Composer installation failed" 
    exit 1 
fi 

        