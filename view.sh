#!/bin/bash

curl -s -x "socks5h://127.0.0.1:1080" --max-time 3 https://api.ipify.org
