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

# Allow different types of backup to be taken all (files and db), db, files
# Could expand this in future to allow media, plugins, themes could also allow a combination e.g db and media
PROVISION_TYPE=`get_config_value 'provision_type' 'all'`
DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
WP_PATH='public_html'
SSH_HOST=`get_config_value 'ssh_host' '31.193.3.183.srvlist.ukfast.net'`
SSH_USER=`get_config_value 'ssh_user' 'relative'`
SSH_PORT=`get_config_value 'ssh_port' '2020'`
DB_BACKUP_NAME=`get_config_value 'db_backup_name' 'vvv-db-backup.sql'`
TAR_NAME=`get_config_value 'tar_name' 'vvv-backup.tar.gz'`
EXCLUDES=`get_config_value 'excludes' 'false'`

# $1: string - The command to run
exec_ssh_cmd()
{
    ssh ${SSH_USER}@${SSH_HOST} $1 -P ${SSH_PORT}
}

# $1: string - The full path of the file to download
exec_scp_cmd()
{
    scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:$1 ${VVV_PATH_TO_SITE}
}

setup_wp_db()
{
    noroot wp config set DB_USER 'wp'
    noroot wp config set DB_PASSWORD 'wp'
    noroot wp db create --dbuser='wp' --dbpass='wp'
    noroot wp db import ${VVV_PATH_TO_SITE}/${DB_BACKUP_NAME} --dbuser='wp' --dbpass='wp'

    noroot wp config set WP_CACHE false --raw

    # Turn error reporting off whilst updating urls
    noroot wp config set WP_DEBUG false --raw

    noroot wp option update home "https://${DOMAIN}"
    if [ $? -eq 0 ]; then
        echo "Home url updated successfully"
    else
        echo "Home url could not be updated because of an error, please review the log to see what went wrong then run: wp option update home \"https://${DOMAIN}\" again."
    fi

    noroot wp option update siteurl "https://${DOMAIN}"

    if [ $? -eq 0 ]; then
        echo "Site url updated successfully"
    else
        echo "Site url could not be updated because of an error, please review the log to see what went wrong then run: wp option update siteurl \"https://${DOMAIN}\" again."
    fi

    noroot wp config set WP_DEBUG true --raw
}

provision_db()
{
    echo "Attempting backup of database"
    exec_ssh_cmd "wp db export --path=${WP_PATH} ${DB_BACKUP_NAME}; exit;"
    
    if [ $? -eq 0 ]; then
        echo "Database backup succeeded"
        echo "Downloading database backup"
        exec_scp_cmd ${DB_BACKUP_NAME}

        if [ $? -eq 0 ]; then
            echo "Database download success"
            echo "Attempting database import"
            setup_wp_db
            echo "Removing DB backup files"
            exec_ssh_cmd "rm -rf ${DB_BACKUP_NAME}; exit;"
            rm -rf ${DB_BACKUP_NAME}
        fi
    else
        echo "FAILED Database backup"
    fi
}

provision_files()
{
    echo "Attempting to create a compressed backup for download, this may take some time"
    # TODO accept custom excludes from vvv-custom

    backup_excludes=""

    if [ $EXCLUDES ]; then
        IFS='- ' read -ra ADDR <<< "$EXCLUDES"
        for i in "${ADDR[@]}"; do
            backup_excludes="${backup_excludes} --exclude=\"${i}\""
        done
    fi

    rsync -azvhu ${backup_excludes} ${SSH_USER}@${SSH_HOST}:${WP_PATH} ./public_html

    echo ${backup_excludes}
    #exec_ssh_cmd "tar -jcf ${TAR_NAME} ${WP_PATH}/* --exclude=\"${WP_PATH}/staging\" --exclude=\"${WP_PATH}/wp-content/infinitewp\" --exclude=\"*.tar\" --exclude=\"*.tar.gz\" --exclude=\"*.zip\" --exclude=\"*.tmp\" --totals; exit;"

    if [ $? -eq 0 ]; then
        #echo "Backup created attempting download"
        #exec_scp_cmd ${TAR_NAME}
    echo "rsync success"

    else
        echo "FAILED to create complete TAR file, this could be due to incorrect file permissions"
    fi
}


# We're probably going to need to ssh into the server at somepoint regardless of what we do so add the host
echo "Adding ${SSH_HOST} to known_hosts"
ssh-keyscan -H ${SSH_HOST} >> /root/.ssh/known_hosts

noroot mkdir -p ${VVV_PATH_TO_SITE}/public_html

if [[ $PROVISION_TYPE == 'all' ]]; then
    provision_files
    provision_db
fi

if [[ $PROVISION_TYPE == 'files' ]]; then
    provision_files
fi

if [[ $PROVISION_TYPE == 'db' ]]; then
    provision_db
fi

# Here we need to decide what we're doing based on the backup type

# Original

#Shouldn't need any of this any more
#echo "Attempting connection to server, backup of db and wp files, this may take some time"

#ssh ${SSH_USER}@${SSH_HOST} "wp db export --path=${WP_PATH} ${DB_BACKUP_NAME}; mv ${DB_BACKUP_NAME} ${WP_PATH}/; tar -jcf ${TAR_NAME} ${WP_PATH}/* --exclude="*.tar" --exclude="*.tar.gz" --exclude="*.zip" --totals; ls ${WP_PATH}; exit;" -P 2020


# echo "Attempting download of backup this may take some time"
# scp -P 2020 ${SSH_USER}@${SSH_HOST}:${TAR_NAME} ${VVV_PATH_TO_SITE}
# echo "Backup downloaded, now attempting extract"
# tar -jxf ${VVV_PATH_TO_SITE}/${TAR_NAME} -C ${VVV_PATH_TO_SITE}




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
