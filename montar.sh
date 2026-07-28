#!/bin/bash


# cat CONFIG/tim_xray.txt  | jq '.v2rUserId, .v2rTlsSni, .v2rHost, .v2rHttpHost'
CONFIG="${1:-config.json}"

USER_ID=$(jq -r '.v2rUserId' $CONFIG)
SNI=$(jq -r '.v2rTlsSni' $CONFIG)
PROXY=$(jq -r '.v2rHost' $CONFIG)
PORTA=443
HOST=$(jq -r '.v2rHttpHost' $CONFIG)


cat <<EOF
vless://$USER_ID@$PROXY:$PORTA?path=%2F&security=tls&encryption=none&insecure=1&host=$HOST&fp=chrome&type=xhttp&allowInsecure=1&sni=$SNI#DragonCore-Free
EOF
echo

cat <<EOF
vless://@$PROXY:$PORTA?path=%2F&security=tls&encryption=none&host=$HOST&fp=chrome&type=xhttp&sni=$SNI
EOF