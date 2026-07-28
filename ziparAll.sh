#!/bin//bash
# MAUVADAO
# VER: 1.0.0
# DATA: qui 04 jun 2026 18:57:43 -03
# COMPACTANDO TODOS DIRETORIOS GIT HUB EXCLUINDO .git

cd "$(dirname "$0")" || exit 1

path='bkp_GitHub'
mkdir -p "$path"
for dir in */; do
dir="${dir%/}"
[ "$dir" = "$path" ] && continue
zip -r "${path}/${dir}.zip" "$dir" -x "*/.git/*" "*/.git"
done
