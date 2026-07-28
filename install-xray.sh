#!/usr/bin/env bash
# Baixa o binário oficial do xray-core (XTLS/Xray-core) para ./bin/xray
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$DIR/bin"
mkdir -p "$BIN_DIR"

if [ -x "$BIN_DIR/xray" ]; then
    echo "xray já instalado: $("$BIN_DIR/xray" version | head -1)"
    exit 0
fi

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
    Linux)
        case "$arch" in
            x86_64) asset="Xray-linux-64.zip" ;;
            aarch64|arm64) asset="Xray-linux-arm64-v8a.zip" ;;
            *) echo "Arquitetura não suportada: $arch" >&2; exit 1 ;;
        esac
        ;;
    Darwin)
        case "$arch" in
            x86_64) asset="Xray-macos-64.zip" ;;
            arm64) asset="Xray-macos-arm64-v8a.zip" ;;
            *) echo "Arquitetura não suportada: $arch" >&2; exit 1 ;;
        esac
        ;;
    *) echo "SO não suportado: $os" >&2; exit 1 ;;
esac

url="https://github.com/XTLS/Xray-core/releases/latest/download/$asset"
echo "Baixando $url ..."
tmp="$(mktemp -d)"
curl -sL -o "$tmp/xray.zip" "$url"
unzip -oq "$tmp/xray.zip" -d "$tmp"
mv "$tmp/xray" "$BIN_DIR/xray"
chmod +x "$BIN_DIR/xray"
rm -rf "$tmp"

echo "Instalado: $("$BIN_DIR/xray" version | head -1)"
