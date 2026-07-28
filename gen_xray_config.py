#!/usr/bin/env python3
"""Converte o config.json do app (formato proprietario v2rXxx) para um
config.json padrao do xray-core, pronto para `xray run -c`.

Uso:
    ./gen_xray_config.py [config.json] [-o xray-config.json] [--socks-port 1080]
"""
import argparse
import json
import ssl
import socket
import hashlib
import sys


def fetch_pinned_cert_sha256(host: str, port: int, sni: str) -> str:
    """Conecta ao servidor e retorna o SHA256 (hex) do certificado apresentado,
    para uso com pinnedPeerCertSha256 quando a validacao normal de hostname
    (SNI x CN/SAN) nao bate — caso comum em configs com allowInsecure=true,
    tipicamente usadas para SNI fronting/anti-bloqueio de operadora."""
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with socket.create_connection((host, port), timeout=10) as sock:
        with ctx.wrap_socket(sock, server_hostname=sni) as tls:
            der = tls.getpeercert(binary_form=True)
    return hashlib.sha256(der).hexdigest()


def build_stream_settings(cfg: dict, fetch_pin: bool) -> dict:
    network = cfg.get("v2rNetwork", "tcp")
    stream = {"network": network}

    security = cfg.get("v2rTleSecurityType", "none")
    if security == "tls":
        stream["security"] = "tls"
        tls = {
            "serverName": cfg.get("v2rTlsSni") or cfg.get("v2rHost", ""),
            "fingerprint": cfg.get("v2rTleFingerprintType", "chrome"),
        }
        if cfg.get("v2rTlsAllowInsecure"):
            if fetch_pin:
                pin = fetch_pinned_cert_sha256(
                    cfg["v2rHost"], int(cfg["v2rPort"]), tls["serverName"]
                )
                tls["pinnedPeerCertSha256"] = pin
                print(f"[info] pinnedPeerCertSha256 obtido: {pin}", file=sys.stderr)
            else:
                print(
                    "[aviso] v2rTlsAllowInsecure=true mas --no-fetch-pin foi usado; "
                    "a conexao TLS provavelmente vai falhar (versoes recentes do "
                    "xray-core removeram 'allowInsecure').",
                    file=sys.stderr,
                )
        stream["tlsSettings"] = tls

    host_header = cfg.get("v2rHttpHost", "")
    path = cfg.get("v2rHttpPath", "/") or "/"

    if network == "xhttp":
        stream["xhttpSettings"] = {"host": host_header, "path": path}
    elif network == "ws":
        stream["wsSettings"] = {"path": path, "host": host_header}
    elif network == "http" or network == "h2":
        stream["httpSettings"] = {"path": path, "host": [host_header] if host_header else []}
    elif network == "grpc":
        stream["grpcSettings"] = {"serviceName": path.lstrip("/")}
    elif network == "tcp":
        header_type = cfg.get("v2rTcpHeaderType", "none")
        if header_type and header_type != "none":
            stream["tcpSettings"] = {"header": {"type": header_type}}
    elif network == "kcp":
        header_type = cfg.get("v2rKcpHeaderType", "none")
        stream["kcpSettings"] = {"header": {"type": header_type}}
    elif network == "quic":
        stream["quicSettings"] = {
            "security": cfg.get("v2rQuicSecurity", "none"),
            "header": {"type": cfg.get("v2rQuicHeaderType", "none")},
        }

    return stream


def build_outbound(cfg: dict, fetch_pin: bool) -> dict:
    protocol = cfg.get("v2rProtocol", "vless")
    host = cfg["v2rHost"]
    port = int(cfg["v2rPort"])

    if protocol == "vless":
        settings = {
            "vnext": [{
                "address": host,
                "port": port,
                "users": [{
                    "id": cfg["v2rUserId"],
                    "encryption": cfg.get("v2rVlessSecurity", "none") or "none",
                    "flow": cfg.get("v2rFlowType", "") if cfg.get("v2rFlowType") != "none" else "",
                }],
            }]
        }
    elif protocol == "vmess":
        settings = {
            "vnext": [{
                "address": host,
                "port": port,
                "users": [{
                    "id": cfg["v2rUserId"],
                    "alterId": int(cfg.get("v2rAlterId", 0) or 0),
                    "security": cfg.get("v2rVmessSecurity", "auto") or "auto",
                }],
            }]
        }
    elif protocol == "trojan":
        settings = {
            "servers": [{
                "address": host,
                "port": port,
                "password": cfg.get("v2rUserId", ""),
            }]
        }
    elif protocol in ("shadowsocks", "ss"):
        settings = {
            "servers": [{
                "address": host,
                "port": port,
                "method": cfg.get("v2rSsSecurity", "none"),
                "password": cfg.get("v2rUserId", ""),
            }]
        }
    else:
        raise ValueError(f"Protocolo nao suportado: {protocol}")

    outbound = {
        "protocol": "shadowsocks" if protocol == "ss" else protocol,
        "settings": settings,
        "streamSettings": build_stream_settings(cfg, fetch_pin),
    }

    if cfg.get("v2rMuxEnabled"):
        outbound["mux"] = {"enabled": True, "concurrency": 8}

    return outbound


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", nargs="?", default="config.json")
    ap.add_argument("-o", "--output", default="xray-config.json")
    ap.add_argument("--socks-port", type=int, default=1080)
    ap.add_argument(
        "--http-port", type=int, default=None,
        help="Se informado, adiciona tambem um inbound HTTP nessa porta.",
    )
    ap.add_argument(
        "--no-fetch-pin", action="store_true",
        help="Nao conectar ao servidor para obter o fingerprint do certificado "
             "(pinnedPeerCertSha256) mesmo se allowInsecure=true.",
    )
    args = ap.parse_args()

    with open(args.input, encoding="utf-8") as f:
        cfg = json.load(f)

    inbounds = [{
        "listen": "127.0.0.1",
        "port": args.socks_port,
        "protocol": "socks",
        "settings": {"udp": True},
    }]
    if args.http_port:
        inbounds.append({
            "listen": "127.0.0.1",
            "port": args.http_port,
            "protocol": "http",
            "settings": {},
        })

    xray_config = {
        "log": {"loglevel": "warning"},
        "inbounds": inbounds,
        "outbounds": [build_outbound(cfg, fetch_pin=not args.no_fetch_pin)],
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(xray_config, f, indent=4, ensure_ascii=False)
        f.write("\n")

    print(f"[ok] gerado {args.output}")


if __name__ == "__main__":
    main()
