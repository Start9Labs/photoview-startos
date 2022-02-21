#!/bin/bash

check_api(){
    DURATION=$(</dev/stdin)
    if (($DURATION <= 5000 )); then 
        exit 60
    else
        res=$(curl --silent --fail 'photoview.embassy:80/api/graphql' -X POST -H 'Content-Type: application/json' --data-raw '{"operationName":"CheckInitialSetup","variables":{},"query":"query CheckInitialSetup { siteInfo { initialSetup }}"}')
        exit_code=$?
        if test "$exit_code" != 0; then
            echo "API unreachable" >&2
            exit 1
        fi
    fi
}

check_web(){
    DURATION=$(</dev/stdin)
    if (($DURATION <= 15000 )); then 
        exit 60
    else
        curl --silent --fail photoview.embassy &>/dev/null
        exit_code=$?
        if test "$exit_code" != 0; then
            echo "Web interface is unreachable" >&2
            exit 1
        fi
    fi
}

case "$1" in
	api)
        check_api
        ;;
	web)
        check_web
        ;;
    *)
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "         api"
        echo "         web"
esac