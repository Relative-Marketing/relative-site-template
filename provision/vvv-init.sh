#!/usr/bin/env bash
# Provision WordPress Stable

echo " * Running relative marketing custom site template"

## Plan

# Setup relative key - x
# Connect to server via ssh - x
# take a backup of the database and put in top level of public_html
# backup the public_html directory
# download that backup
# extract to own public_html directory
# import the database

DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
WP_PATH='public_html'
SSH_HOST='31.193.3.183.srvlist.ukfast.net'
DB_BACKUP='vvv-db-backup.sql'
TAR_NAME='vvv-backup.tar.gz'
FORCE_BACKUP=`get_config_value 'force_backup' false`
if ! $(noroot wp core is-installed) || FORCE_BACKUP; then

  echo "Adding ${SSH_HOST} to known_hosts"
  ssh-keyscan -H ${SSH_HOST} >> /root/.ssh/known_hosts
  echo "Attempting connection to server, backup of db and wp files"
  #ssh relative@${SSH_HOST} "wp db export --path=${WP_PATH} ${DB_BACKUP}; mv ${DB_BACKUP} ${WP_PATH}/; tar -jcvf ${TAR_NAME} ${WP_PATH}/* --exclude="*.tar" --exclude="*.tar.*" --exclude="*.zip" --totals; ls ${WP_PATH}; exit;" -P 2020

  noroot mkdir -p ${VVV_PATH_TO_SITE}/public_html

  echo "Attempting download of backup this may take some time"
  #scp -P 2020 relative@${SSH_HOST}:${TAR_NAME} ${VVV_PATH_TO_SITE}
  echo "Backup downloaded, now attempting extract"
  #tar -jxvf ${VVV_PATH_TO_SITE}/${TAR_NAME} -C ${VVV_PATH_TO_SITE}

fi

noroot wp db create --dbuser='wp' --dbpass='wp'
noroot wp db import public_html/${DB_BACKUP} --dbuser='wp' --dbpass='wp'
# DB_NAME=`noroot wp config get DB_NAME`
# mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"

noroot wp config set WP_DEBUG true --raw
noroot wp config set DB_USER 'wp'
noroot wp config set DB_PASSWORD 'wp'
noroot wp option update home ${DOMAIN}
noroot wp option update siteurl ${DOMAIN}



echo "Setting up the log subfolder for Nginx logs"
noroot mkdir -p ${VVV_PATH_TO_SITE}/log
noroot touch ${VVV_PATH_TO_SITE}/log/nginx-error.log
noroot touch ${VVV_PATH_TO_SITE}/log/nginx-access.log

noroot touch ${VVV_PATH_TO_SITE}/public_html/index.php

echo "Copying the sites Nginx config template ( fork this site template to customise the template )"
cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
  echo "Inserting the SSL key locations into the sites Nginx config"
  VVV_CERT_DIR="/srv/certificates"
  # On VVV 2.x we don't have a /srv/certificates mount, so switch to /vagrant/certificates
  codename=$(lsb_release --codename | cut -f2)
  if [[ $codename == "trusty" ]]; then # VVV 2 uses Ubuntu 14 LTS trusty
    VVV_CERT_DIR="/vagrant/certificates"
  fi
  sed -i "s#{{TLS_CERT}}#ssl_certificate ${VVV_CERT_DIR}/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
  sed -i "s#{{TLS_KEY}}#ssl_certificate_key ${VVV_CERT_DIR}/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi
