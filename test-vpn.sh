#!/usr/bin/env bash
# Testa de ponta a ponta o config.json do app: instala o xray-core se preciso,
# converte a config, sobe um proxy SOCKS local e verifica se o trafego real
# passa pelo servidor configurado.
#
# Uso: ./test-vpn.sh [config.json]
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_IN="${1:-$DIR/config.json}"
XRAY_CFG="$DIR/xray-config.json"
XRAY_BIN="$DIR/bin/xray"
XRAY_LOG="$DIR/xray.log"
SOCKS_PORT=1080

cleanup() {
    if [ -n "${XRAY_PID:-}" ] && kill -0 "$XRAY_PID" 2>/dev/null; then
        kill "$XRAY_PID" 2>/dev/null || true
        wait "$XRAY_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "== 1/5: verificando binario do xray =="
"$DIR/install-xray.sh"

echo "== 2/5: gerando xray-config.json a partir de $CONFIG_IN =="
python3 "$DIR/gen_xray_config.py" "$CONFIG_IN" -o "$XRAY_CFG" --socks-port "$SOCKS_PORT"

echo "== 3/5: validando sintaxe =="
"$XRAY_BIN" run -test -c "$XRAY_CFG"

echo "== 4/5: subindo xray em background (porta $SOCKS_PORT) =="
"$XRAY_BIN" run -c "$XRAY_CFG" > "$XRAY_LOG" 2>&1 &
XRAY_PID=$!

for _ in $(seq 1 20); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$SOCKS_PORT") 2>/dev/null; then
        exec 3<&- 3>&-
        break
    fi
    if ! kill -0 "$XRAY_PID" 2>/dev/null; then
        echo "xray caiu ao iniciar. Log:" >&2
        cat "$XRAY_LOG" >&2
        exit 1
    fi
    sleep 0.3
done

echo "== 5/5: testando conectividade real =="
direct_ip="$(curl -s --max-time 8 https://api.ipify.org || true)"
direct_ip="${direct_ip:-falhou}"
tunnel_ip="$(curl -s -x "socks5h://127.0.0.1:$SOCKS_PORT" --max-time 20 https://api.ipify.org || true)"
tunnel_ip="${tunnel_ip:-falhou}"

status_204="$(curl -s -o /dev/null -w '%{http_code}' -x "socks5h://127.0.0.1:$SOCKS_PORT" --max-time 20 https://www.gstatic.com/generate_204 || true)"
if [ "$status_204" != "204" ]; then
    # o transporte XHTTP as vezes tem latencia alta na 1a requisicao por rota; tenta mais uma vez
    status_204="$(curl -s -o /dev/null -w '%{http_code}' -x "socks5h://127.0.0.1:$SOCKS_PORT" --max-time 20 https://www.gstatic.com/generate_204 || true)"
fi
status_204="${status_204:-000}"

echo ""
echo "----------------------------------------"
echo "IP direto (sem VPN):   $direct_ip"
echo "IP via config.json:    $tunnel_ip"
echo "Teste HTTP (gstatic):  $status_204"
echo "----------------------------------------"

if [ "$status_204" = "204" ] && [ "$tunnel_ip" != "$direct_ip" ] && [ "$tunnel_ip" != "falhou" ]; then
    echo "RESULTADO: config.json FUNCIONANDO."
    exit 0
else
    echo "RESULTADO: FALHOU. Veja o log em $XRAY_LOG"
    exit 1
fi
