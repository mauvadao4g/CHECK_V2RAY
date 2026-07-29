#!/bin/bash
# MAUVADAO
# COMPACTANDO TODOS DIRETORIOS GIT HUB EXCLUINDO .git

cd "$(dirname "$0")" || exit 1

timestamp=$(date +%s)
path='bkp_v2ray'
mkdir -p "$path"

dir="."
zip -r "${path}/bkp_${timestamp}.zip" "$dir" -x "*/.git/*" "*/.git" "bkp_v2ray/*"
