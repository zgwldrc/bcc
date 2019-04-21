#!/bin/bash
# ss-server

set -e
PUBLIC_ADDR=`curl ifconfig.co`
PORT=`shuf -i 2000-65000 -n 1`
PASSWORD=`date +%s | sha256sum | base64 | head -c 32 ; echo`
METHOD="chacha20-ietf-poly1305"
METHOD_PASSWORD_ENCODEED=`echo -n "$METHOD:$PASSWORD" | base64`
docker run -dt -p $PORT:$PORT mritd/shadowsocks -s "-s 0.0.0.0 -p $PORT -m chacha20-ietf-poly1305 -k $PASSWORD"
echo "ss://$METHOD_PASSWORD_ENCODEED@$PUBLIC_ADDR:$PORT"