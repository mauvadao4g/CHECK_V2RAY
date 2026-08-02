#!/bin/bash
# MAUVADAO
# VER: 0.0.0
# DATA: dom 28 jun 2026 11:24:38 -03

# comando:
# ssh -fN -D 8000 teste7960@45.157.157.117

porta=8000
user="teste7960"
host="45.157.157.117"

echo -e "\e[1;31mComando: \e[1;34mssh -fN -D 8000 teste7960@45.157.157.117\e[0m"
echo ""

# Ligando socks5:
proxy_rodando() {
    local porta="$1"

    ss -lntp 2>/dev/null | grep -q ":$porta " && return 0
    return 1
}

if proxy_rodando "$porta"; then
    echo -e "\e[1;31mProxy já ativo\e[0m"
else
    ssh -fN -D "$porta" "${user}@${host}" >/dev/null 2>&1 && echo -e "\e[1;32mProxy Ativo: localhost:${porta}\e[0m"
fi
