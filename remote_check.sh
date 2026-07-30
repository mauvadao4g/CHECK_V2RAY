#!/bin/bash

[ -z "$1" ] && {
    echo "Uso: $0 arquivo"
    exit 1
}

FILE="$1"

bash cmd.sh "find . -type f -iname '$FILE' -exec bash test-vpn.sh {} +"
