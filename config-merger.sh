#!/bin/bash

set -eo pipefail
set -x

UID=${UID:-1000}
TEMP_CONFIG_DIR=/elasticsearch/temp-config
CUSTOM_CONFIG_DIR=/elasticsearch/custom-config
CONFIG_DIR=/usr/share/elasticsearch/config
CONFIG_FILE=/usr/share/elasticsearch/config/elasticsearch.yml

echo "changing the ownership of data folder: /usr/share/elasticsearch/data"
chown -R $UID:$UID /usr/share/elasticsearch/data

# process elasticsearch.yml
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
