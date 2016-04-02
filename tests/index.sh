#!/usr/bin/env bash

printf '%.0s-' {1..40}
echo

URL=$1
WEBURL=$2

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

testInviteNotEMail() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/invite/no-email)

    assertTrue 404 $RESPONSE $FUNCNAME
}

testInviteSuccess() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/invite/teleport@imega.ru)

    assertTrue 200 $RESPONSE $FUNCNAME
}

testAccountSuccess() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/account/db4e2a20-31bf-4001-c0f9-2245d260bc2e)

    assertTrue 200 $RESPONSE $FUNCNAME
}

testAccountFail() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/account/db4e2)

    assertTrue 404 $RESPONSE $FUNCNAME
}

testAccountDoubleMail() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/account/db4e2a20-31bf-4001-c0f9-2245d260bc2e)

    assertTrue 409 $RESPONSE $FUNCNAME
}

testAccountFailToken() {
    RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null http://$URL/account/22222222-2222-2222-2222-222222222222)

    assertTrue 404 $RESPONSE $FUNCNAME
}

testRegisterSuccess() {
    RESPONSE=$(curl -X POST -d '{"url":"'$WEBURL'"}' --write-out %{http_code} --silent --output /dev/null http://$URL/register-plugin/9915e49a-4de1-41aa-9d7d-c9a687ec048d)

    assertTrue 200 $RESPONSE $FUNCNAME
}

testInviteNotEMail
testInviteSuccess
testAccountSuccess
testAccountFail
testAccountDoubleMail
testAccountFailToken
testRegisterSuccess

printf '%.0s-' {1..40}
echo
printf 'Total test: %s, fail: %s\n\n' "$COUNT_TESTS" "$COUNT_TESTS_FAIL"

if [ $COUNT_TESTS_FAIL -gt 0 ]; then
    exit 1
fi

exit 0
