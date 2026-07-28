#!/bin/bash


# cat CONFIG/tim_xray.txt  | jq '.v2rUserId, .v2rTlsSni, .v2rHost, .v2rHttpHost'
CONFIG="${1:-config.json}"
AZION='j7a9hucbypk.map.azionedge.net'
UUID='e30b8dc3-ed92-476f-ab42-ef95edc1d7c8'

# USER_ID="$(jq '.v2rUserId' <<<$CONFIG)"
# SNI='authconnect.tim.com.br'
# PROXY='179.191.168.17'
# PORTA='443'
# HOST=''

USER_ID=$(jq -r '.v2rUserId' $CONFIG)
SNI=$(jq -r '.v2rTlsSni' $CONFIG)
PROXY=$(jq -r '.v2rHost' $CONFIG)
PORTA=443
HOST=$(jq -r '.v2rHttpHost' $CONFIG)


cat <<EOF
vless://$USER_ID@$PROXY:$PORTA?path=%2F&security=tls&encryption=none&insecure=1&host=$HOST&fp=chrome&type=xhttp&allowInsecure=1&sni=$SNI#DragonCore-Free
EOF
