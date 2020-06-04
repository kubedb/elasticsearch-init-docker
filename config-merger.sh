#!/bin/bash

set -eo pipefail
set -x

UID=${UID:-1000}
DEFAULT_SECURITY_CONFIG_DIR=/securityconfig
TEMP_CONFIG_DIR=/elasticsearch/temp-config
CUSTOM_CONFIG_DIR=/elasticsearch/custom-config
CONFIG_DIR=/usr/share/elasticsearch/config
CONFIG_FILE=/usr/share/elasticsearch/config/elasticsearch.yml
SECURITY_CONFIG_DIR=/usr/share/elasticsearch/plugins/opendistro_security/securityconfig

# load default security configuration files
cp -r $DEFAULT_SECURITY_CONFIG_DIR/* $SECURITY_CONFIG_DIR/

for FILE_DIR in $SECURITY_CONFIG_DIR/*
do
  FILE_NAME=$(basename -- $FILE_DIR)

  # operator generated file
  if [ -f $TEMP_CONFIG_DIR/$FILE_NAME ]; then
      yq merge -i --overwrite $FILE_DIR $TEMP_CONFIG_DIR/$FILE_NAME
  fi

  # user provided file
  if [ -f $CUSTOM_CONFIG_DIR/$FILE_NAME ]; then
    yq merge -i --overwrite $FILE_DIR $CUSTOM_CONFIG_DIR/$FILE_NAME
  fi
done

echo "changing the ownership of securityconfig directory: /usr/share/elasticsearch/plugins/opendistro_security/securityconfig"
chown -R $UID:0 $SECURITY_CONFIG_DIR

echo "changing the ownership of data folder: /usr/share/elasticsearch/data"
chown -R $UID:$UID /usr/share/elasticsearch/data
