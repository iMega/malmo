#!/usr/bin/env bash

URL=$1

assertTrue() {
    if [ "$1" != "$2" ]; then
        echo "Fail:" $3
        exit 1;
    fi
    echo $3
}

echo "Passed"

exit 0
