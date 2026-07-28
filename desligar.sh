#!/usr/bin/env bash
# Desliga a conexao ligada por ./ligar.sh
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$DIR/xray.pid"
STATE_FILE="$DIR/.xray-active-config"

if [ ! -f "$PID_FILE" ] || ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "Nao esta ligado."
    rm -f "$PID_FILE" "$STATE_FILE"
    exit 0
fi

PID="$(cat "$PID_FILE")"
kill "$PID"
for _ in $(seq 1 20); do
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.2
done
kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true

rm -f "$PID_FILE" "$STATE_FILE"
echo "Desligado."
