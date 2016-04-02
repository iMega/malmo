#!/usr/bin/env bash

printf '%.0s-' {1..40}
echo

URL=$1
COUNT_TESTS=0
COUNT_TESTS_FAIL=0

assertTrue() {
    testName="$3"
    pad=$(printf '%0.1s' "."{1..40})
    padlength=38

    if [ "$1" != "$2" ]; then
        printf ' %s%*.*s%s' "$3" 0 $((padlength - ${#testName} - 4)) "$pad" "Fail"
        printf ' (assertion %s, expected %s)\n' "$1" "$2"
        let "COUNT_TESTS_FAIL++"
    else
        printf ' %s%*.*s%s\n' "$3" 0 $((padlength - ${#testName} - 2)) "$pad" "Ok"
        let "COUNT_TESTS++"
    fi
}

testSuccessAuth() {
    RESPONSE=$(curl -u '9915e49a-4de1-41aa-9d7d-c9a687ec048d:8c279a62-88de-4d86-9b65-527c81ae767a' --write-out %{http_code} --silent --output /dev/null http://$URL)

    assertTrue 200 $RESPONSE $FUNCNAME
}

testFailNotAuth() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL)

    assertTrue 400 $RESPONSE $FUNCNAME
}

testFail() {
    RESPONSE=$(curl -u 'faillogin:failpass' --write-out %{http_code} --silent --output /dev/null http://$URL)

    assertTrue 400 $RESPONSE $FUNCNAME
}

testFailAuth() {
    RESPONSE=$(curl -u '8815e49a-4de1-41aa-9d7d-c9a687ec048d:8c279a62-88de-4d86-9b65-527c81ae767a' --write-out %{http_code} --silent --output /dev/null http://$URL)

    assertTrue 401 $RESPONSE $FUNCNAME
}

testSuccessAuth
testFailNotAuth
testFail
testFailAuth

printf '%.0s-' {1..40}
echo
printf 'Total test: %s, fail: %s\n\n' "$COUNT_TESTS" "$COUNT_TESTS_FAIL"

if [ $COUNT_TESTS_FAIL -gt 0 ]; then
    exit 1
fi

exit 0
