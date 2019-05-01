#!/bin/bash
PROXY_SETTING="-x 127.0.0.1:1087"
TOKEN=""
BRANCH="master"

TRIGGER_URL=""
PIPELINES_URL=""

id=`curl $PROXY_SETTING -s -X POST \
    -F token=$TOKEN \
    -F "ref=$BRANCH" \

    $TRIGGER_URL | jq '.id'`

open $PIPELINES_URL/$id