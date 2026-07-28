#!/bin/bash

[[ "$1" == '--info' || "$1" == '-h' ]] && echo "Usage: $0 <v2rUserId> <v2rHttpHost> <v2rTlsSni> <v2rPort>" && exit 1


CONFIG='new.json'
# jq . $CONFIG

U="0265c394-17ab-4130-85a6-63ff76a5c4e0" # v2rUserId
H="meu.host.com" # v2rHttpHost
S="www.tim.com.br" # v2rTlsSni
P=443



UUI="${1:-$U}" # v2rUserId
HOST="${2:-$H}" # v2rHttpHost
SNI="${3:-$S}" # v2rTlsSni
PORTA=${4:-$P}



jq \
  --arg uuid "$UUID" \
  --arg host "$HOST" \
  --arg sni "$SNI" \
  --argjson port "$PORTA" \
'
.v2rUserId   = $uuid |
.v2rHttpHost = $host |
.v2rTlsSni   = $sni |
.v2rPort     = $port
' new.json



