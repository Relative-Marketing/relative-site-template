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
WP_PATH=`get_config_value 'wp_path' 'public_html'`
SSH_HOST=`get_config_value 'ssh_host' 'false'`
SSH_USER=`get_config_value 'ssh_user' 'false'`
SSH_PORT=`get_config_value 'ssh_port' '2020'`
DB_BACKUP_NAME=`get_config_value 'db_backup_name' 'vvv-db-backup.sql'`
EXCLUDES=`get_config_value 'backup_exclude' 'false'`

# $1: string - The command to run
exec_ssh_cmd()
{
    echo "Attempting noroot ssh"
    noroot ssh -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST} $1

    if [ ! $? -eq 0 ]; then
        echo "noroot ssh failed attempting as root"
        ssh -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST} $1

        if [ ! $? -eq 0 ]; then
            echo "noroot and root ssh command failed"
        else
            echo "ssh command success as root"
        fi
    else
        echo "ssh command success"
    fi
}

# $1: string - The full path of the file to download
exec_scp_cmd()
{
    echo "Attempting noroot scp"
    noroot scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:$1 ${VVV_PATH_TO_SITE}

    if [ ! $? -eq 0 ]; then
        echo "noroot scp failed attempting as root"
        scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:$1 ${VVV_PATH_TO_SITE}
        
        if [ ! $? -eq 0 ]; then
            echo "noroot and root scp command failed"
        else
            echo "scp command success as root"
        fi
    else
        echo "scp command success"
    fi
}

setup_wp_db()
{
    noroot wp config set DB_USER 'wp'
    noroot wp config set DB_PASSWORD 'wp'
    db_name=`noroot wp config get DB_NAME`
    echo -e "\033[31mCreating database"
    mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${db_name}"
    echo -e "\033[31mGranting wp user priviledges to the '${db_name}' database"
    mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO wp@localhost IDENTIFIED BY 'wp';"

    echo -e "\033[31mAttempting import of database"
    noroot wp db import ${VVV_PATH_TO_SITE}/${DB_BACKUP_NAME} --dbuser='wp' --dbpass='wp'
    
    noroot wp config set WP_CACHE false --raw
    
    noroot wp config set WP_DEBUG false --raw
    
    noroot wp plugin deactivate w3-total-cache
    
    noroot wp option update home "https://${DOMAIN}"
    if [ $? -eq 0 ]; then
        echo -e "\033[31mHome url updated successfully\e[0m"
    else
        echo -e "\033[31mHome url could not be updated because of an error, please review the log to see what went wrong then run: wp option update home \"https://${DOMAIN}\" again.\e[0m"
    fi

    noroot wp option update siteurl "https://${DOMAIN}"

    if [ $? -eq 0 ]; then
        echo -e "\033[31mSite url updated successfully\e[0m"
    else
        echo -e "\033[31mSite url could not be updated because of an error, please review the log to see what went wrong then run: wp option update siteurl \"https://${DOMAIN}\" again.\e[0m"
    fi
    
    noroot wp config set WP_DEBUG true --raw

}

provision_db()
{
    # We can't count on the remote host to have wp-cli installed so to get around that use a .my.cnf file and delete once done

    # Download the wp-config file
    noroot scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${WP_PATH}/wp-config.php ${VVV_PATH_TO_SITE}/public_html
    
    if [ ! $? -eq 0 ]; then
        scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${WP_PATH}/wp-config.php ${VVV_PATH_TO_SITE}/public_html
    fi

    # store the required credentials
    db_name=`noroot wp config get DB_NAME`
    db_user=`noroot wp config get DB_USER`
    db_pass=`noroot wp config get DB_PASSWORD`

    # create the file and add the needed credentials
    touch ${VVV_PATH_TO_SITE}/.my.cnf
    echo -e "\033[31mCreating .my.cnf for remote mysqldump\e[0m"
    echo -e "[mysqldump]\nuser=${db_user}\npassword='${db_pass}'" > ${VVV_PATH_TO_SITE}/.my.cnf

    echo -e "\033[31mUploading config\e[0m"
    noroot scp -P ${SSH_PORT} ${VVV_PATH_TO_SITE}/.my.cnf ${SSH_USER}@${SSH_HOST}:~/

    if [ ! $? -eq 0 ]; then
        scp -P ${SSH_PORT} ${VVV_PATH_TO_SITE}/.my.cnf ${SSH_USER}@${SSH_HOST}:~/
        
        if [ ! $? -eq 0 ]; then
            echo -e "\033[31mUploading .cnf failed as root\e[0m"
        fi
    fi
    
    echo -e "\033[31mAttempting database backup\e[0m"

    # dump the backup
    exec_ssh_cmd "mysqldump --login-path='~/.my.cnf' -u ${db_user} ${db_name} > ${DB_BACKUP_NAME}"

    exec_scp_cmd ${DB_BACKUP_NAME}

    # remove the cnf file locally and on remote
    echo -e "\033[31mCleanup .my.cnf\e[0m"
    rm -rf ${VVV_PATH_TO_SITE}/.my.cnf
    exec_ssh_cmd "rm -rf ~/.my.cnf ${DB_BACKUP_NAME}"

    setup_wp_db
}

provision_files()
{
    echo -e "\033[31mAttempting to create a compressed backup for download, this may take some time\e[0m"

    backup_excludes=""

    if [ $EXCLUDES ]; then
        IFS=',' read -ra ADDR <<< "$EXCLUDES"
        for i in "${ADDR[@]}"; do
            if [[ $i != *"*"* ]]; then
                i="/${WP_PATH}/${i}"
            fi
            backup_excludes="${backup_excludes}--exclude=${i} "
        done
    fi

    rsync -azvhu -e "ssh -p ${SSH_PORT}" ${backup_excludes}${SSH_USER}@${SSH_HOST}:${WP_PATH}/* ${VVV_PATH_TO_SITE}/public_html

    if [ $? -eq 0 ]; then
        echo -e "\033[31mFile sync success\e[0m"
    else
        echo -e "\033[31mFAILED to sync files trying root attempting as noroot\e[0m"
        noroot rsync -azvhu -e "ssh -p ${SSH_PORT}" ${backup_excludes}${SSH_USER}@${SSH_HOST}:${WP_PATH} ${VVV_PATH_TO_SITE}
    fi
}

if [[ ( ! ${SSH_HOST} ) || ( ! ${SSH_USER} ) ]]; then
    echo "Error: You must specify an ssh_user and ssh_host, see readme for examples" 
    exit 1
else
    # We're probably going to need to ssh into the server at somepoint regardless of what we do so add the host
    echo -e "\033[31mAdding ${SSH_HOST} to known_hosts\e[0m"

    noroot ssh-keyscan -p ${SSH_PORT} -H ${SSH_HOST} >> ~/.ssh/known_hosts

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
fi
