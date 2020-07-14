#!/bin/bash

set -eo pipefail
set -x

UID=${UID:-1000}
AUTH_PLUGIN=${AUTH_PLUGIN:-""}
TEMP_CONFIG_DIR=/elasticsearch/temp-config
CUSTOM_CONFIG_DIR=/elasticsearch/custom-config
CONFIG_DIR=/usr/share/elasticsearch/config
CONFIG_FILE=/usr/share/elasticsearch/config/elasticsearch.yml

echo "changing the ownership of data folder: /usr/share/elasticsearch/data"
chown -R $UID:$UID /usr/share/elasticsearch/data

# -------------------- OpenDistro & SearchGuard -------------------- #

if [[ "$AUTH_PLUGIN" == "OpenDistro" ]]; then
  DEFAULT_SECURITY_CONFIG_DIR=/securityconfig
  SECURITY_CONFIG_DIR=/usr/share/elasticsearch/plugins/opendistro_security/securityconfig
elif [[ "$AUTH_PLUGIN" == "SearchGuard" ]]; then
  DEFAULT_SECURITY_CONFIG_DIR=/sgconfig
  SECURITY_CONFIG_DIR=/usr/share/elasticsearch/plugins/search-guard-7/sgconfig
fi

if [[ "$AUTH_PLUGIN" != "X-Pack" ]]; then
  # security config directory won't exist, when security is disabled by user.
  if [ -d $SECURITY_CONFIG_DIR ]; then
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

    echo "changing the ownership of securityconfig/sgconfig directory"
    chown -R $UID:0 $SECURITY_CONFIG_DIR
  fi

fi

# -------------------- X-Pack & OpenDistro & SearchGuard-------------------- #

if [ -f $TEMP_CONFIG_DIR/elasticsearch.yml ]; then
  cp $TEMP_CONFIG_DIR/elasticsearch.yml $CONFIG_FILE
else
  touch $CONFIG_FILE
fi

# yq changes the file permissions after merging custom configuration.
# we need to restore the original permissions after merging done.
ORIGINAL_PERMISSION=$(stat -c '%a' $CONFIG_FILE)

# if common-config file exist then apply it
if [ -f $CUSTOM_CONFIG_DIR/common-elasticsearch.yml ]; then
  yq merge -i --overwrite $CONFIG_FILE $CUSTOM_CONFIG_DIR/common-elasticsearch.yml
fi

# if it is data node and data-config file exist then apply it
if [[ "$NODE_DATA" == true ]]; then
  if [ -f $CUSTOM_CONFIG_DIR/data-elasticsearch.yml ]; then
    yq merge -i --overwrite $CONFIG_FILE $CUSTOM_CONFIG_DIR/data-elasticsearch.yml
  fi
fi

# if it is client node and client-config file exist then apply it
if [[ "$NODE_INGEST" == true ]]; then
  if [ -f $CUSTOM_CONFIG_DIR/client-elasticsearch.yml ]; then
    yq merge -i --overwrite $CONFIG_FILE $CUSTOM_CONFIG_DIR/client-elasticsearch.yml
  fi
fi

# if it is master node and mater-config file exist then apply it
if [[ "$NODE_MASTER" == true ]]; then
  if [ -f $CUSTOM_CONFIG_DIR/master-elasticsearch.yml ]; then
    yq merge -i --overwrite $CONFIG_FILE $CUSTOM_CONFIG_DIR/master-elasticsearch.yml
  fi
fi

# restore original permission of elasticsearh.yml file
if [[ "$ORIGINAL_PERMISSION" != "" ]]; then
  chmod $ORIGINAL_PERMISSION $CONFIG_FILE
fi


