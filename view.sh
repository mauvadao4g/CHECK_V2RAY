#!/bin/bash

ip_externo=$(curl -s --max-time 3 https://api.ipify.org)
ip_vpn=$(curl -s -x "socks5h://127.0.0.1:1080" --max-time 3 https://api.ipify.org)

echo -e  "\e[1;32mExterno: \e[1;33m$ip_externo\e[0m"
echo -e  "\e[1;32mVpn: \e[1;33m$ip_vpn\e[0m"
