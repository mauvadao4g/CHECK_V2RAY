#!/usr/bin/env bash
# Liga a conexao do config.json como proxy local (SOCKS5 + HTTP), rodando em
# background. Use ./desligar.sh para parar.
#
# Uso: ./ligar.sh [config.json]
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_IN="${1:-$DIR/config.json}"
XRAY_CFG="$DIR/xray-config.json"
XRAY_BIN="$DIR/bin/xray"
XRAY_LOG="$DIR/xray.log"
PID_FILE="$DIR/xray.pid"
STATE_FILE="$DIR/.xray-active-config"
SOCKS_PORT=1080
HTTP_PORT=1081

CONFIG_ABS="$(readlink -f "$CONFIG_IN")"
CONFIG_HASH="$(sha256sum "$CONFIG_IN" | cut -d' ' -f1)"
CONFIG_ID="$CONFIG_ABS $CONFIG_HASH"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$CONFIG_ID" ]; then
        echo "Ja esta ligado (PID $(cat "$PID_FILE")) com essa mesma config."
        echo "SOCKS5 : 127.0.0.1:$SOCKS_PORT"
        echo "HTTP   : 127.0.0.1:$HTTP_PORT"
        exit 0
    fi
    echo "== config diferente da que esta ligada, trocando =="
    "$DIR/desligar.sh"
fi
rm -f "$PID_FILE"

echo "== verificando binario do xray =="
"$DIR/install-xray.sh"

echo "== gerando xray-config.json a partir de $CONFIG_IN =="
python3 "$DIR/gen_xray_config.py" "$CONFIG_IN" -o "$XRAY_CFG" \
    --socks-port "$SOCKS_PORT" --http-port "$HTTP_PORT"

echo "== validando sintaxe =="
"$XRAY_BIN" run -test -c "$XRAY_CFG"

echo "== ligando =="
setsid "$XRAY_BIN" run -c "$XRAY_CFG" < /dev/null > "$XRAY_LOG" 2>&1 &
echo $! > "$PID_FILE"

ok=0
for _ in $(seq 1 20); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$SOCKS_PORT") 2>/dev/null; then
        exec 3<&- 3>&-
        ok=1
        break
    fi
    if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        break
    fi
    sleep 0.3
done

if [ "$ok" != "1" ]; then
    echo "Falhou ao ligar. Log:" >&2
    cat "$XRAY_LOG" >&2
    rm -f "$PID_FILE"
    exit 1
fi

echo "$CONFIG_ID" > "$STATE_FILE"

echo ""
echo "Conectado (PID $(cat "$PID_FILE"))."
echo ""
echo "SOCKS5 : 127.0.0.1:$SOCKS_PORT"
echo "HTTP   : 127.0.0.1:$HTTP_PORT"
echo ""
echo "Para usar no terminal atual:"
echo "  export http_proxy=http://127.0.0.1:$HTTP_PORT https_proxy=http://127.0.0.1:$HTTP_PORT"
echo "  export ALL_PROXY=socks5h://127.0.0.1:$SOCKS_PORT"
echo ""
echo "Para desligar: ./desligar.sh"
