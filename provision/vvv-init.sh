#!/usr/bin/env bash
# Provision WordPress Stable

echo " * TEST TEST TEST"

ssh-keyscan -H 31.193.3.183.srvlist.ukfast.net >> /root/.ssh/known_hosts
ssh devrelative@31.193.3.183.srvlist.ukfast.net "logout" -P 2020

echo " DID THE PWD"

echo "Setting up the log subfolder for Nginx logs"
noroot mkdir -p ${VVV_PATH_TO_SITE}/log
noroot touch ${VVV_PATH_TO_SITE}/log/nginx-error.log
noroot touch ${VVV_PATH_TO_SITE}/log/nginx-access.log

noroot mkdir -p ${VVV_PATH_TO_SITE}/public_html