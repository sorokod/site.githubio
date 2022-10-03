#!/bin/bash


SRC_DIR=.
#DST_DIR=../../../tmp/hugo-staging
DST_DIR=../sorokod.github.io
TMP_DIR=../../../tmp/hugo-tmp

#LOG=./hugo.log


echo -e "\033[0;32m### Generating content: $SRC_DIR ===> $TMP_DIR\033[0m"
hugo --source="$SRC_DIR" --destination="$TMP_DIR"

if [ $? -eq 0 ]; then
    echo -e "\033[0;32m### Syncing $TMP_DIR ===> $DST_DIR\033[0m"
    rsync -a  "$TMP_DIR/" "$DST_DIR"
fi

echo -e "\033[0;32m### Cleaning up\033[0m"
rm -rf $TMP_DIR

