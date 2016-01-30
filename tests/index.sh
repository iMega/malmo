#!/usr/bin/env bash

URL=$1

assertTrue() {
    if [ "$1" != "$2" ]; then
        echo "Fail:" $3
        exit 1;
    fi
    echo $3
}

testFailSettings() {
    RESPONSE=$(curl -X POST --user fail:user --write-out %{http_code} --silent --output /dev/null http://$URL)

    assertTrue 400 $RESPONSE testFailSettings
}

testSettings() {
    RESPONSE=$(curl -X POST --user 9915e49a-4de1-41aa-9d7d-c9a687ec048d:8c279a62-88de-4d86-9b65-527c81ae767a --write-out %{http_code} --silent --output /dev/null -d '{
        "sku_article_barcode": true,
        "show_kode_good": false,
        "good_discription_file": true,
        "show_fullname_good": false
    }' http://$URL)

    assertTrue 200 $RESPONSE testSettings
}

testFailSettings
testSettings

echo "Passed"

exit 0
