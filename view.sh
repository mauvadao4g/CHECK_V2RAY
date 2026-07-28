#!/bin/bash

ip_externo=$(curl -s --max-time 3 https://api.ipify.org)
ip_vpn=$(curl -s -x "socks5h://127.0.0.1:1080" --max-time 3 https://api.ipify.org)

echo "Externo: $ip_externo"
echo "Vpn: $ip_vpn"
