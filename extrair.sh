#!/bin/bash

link="$2"

# Extrair o UUID do link
 uuid=$(echo "$link" | grep -oP '(?<=vless://)[^@]+')
# Extrair o host do link
  host=$(echo "$link" | grep -oP '(?<=@)[^:]+')
 
# Extrair a porta do link
 port=$(echo "$link" | grep -oP '(?<=:)[0-9]+(?=\?)')

# Extrair dominio
 dominio=$(echo "$link" | grep -oP '(?<=host=)[^&]+'  | sed 's/#.*//')

# Extrair path
 path=$(echo "$link" | grep -oP '(?<=path=)[^&]+')

# extrair sn
 sni=$(echo "$link" | grep -oP '(?<=sni=)[^&]+' | sed 's/#.*//')

# Exibir os resultados
_mostrar(){
cat <<EOF
UUID: $uuid
Host: $host
Port: $port
Dominio: $dominio
Sni: $sni
Path: $path

EOF
}
_payload(){
###  MONTANDO PAYLOAD ####
cat <<PAYLOAD
{
    "v2rTleSecurityType": "tls",
    "v2rProtocol": "vless",
    "v2rQuicHeaderType": "none",
    "customDns1": "",
    "v2rTlsSni": "$sni",
    "v2rQuicSecurity": "none",
    "v2rCoreType": "xray",
    "v2rFragmentPackets": "tlshello",
    "v2rSsSecurity": "none",
    "configVersionCode": 0,
    "v2rHttpHost": "$dominio",
    "v2rRoutingRules": "proxy_all",
    "configTimestamp": 1784924466,
    "v2rUserId": "$uuid",
    "v2rVmessSecurity": "none",
    "v2rNetwork": "xhttp",
    "v2rHttpPath": "/",
    "v2rIsGuiMode": true,
    "v2rFragmentEnabled": false,
    "v2rHost": "$host",
    "v2rPort": "$port",
    "configSalt": "",
    "v2rVlessSecurity": "none",
    "configLockMobileOperatorId": "",
    "v2rTleFingerprintType": "chrome",
    "dnsType": 3,
    "v2rMuxEnabled": false,
    "v2rTcpHeaderType": "none",
    "v2rAlterId": "0",
    "isDefaultRoute": true,
    "isPublicKey": false,
    "v2rFlowType": "none",
    "v2rTlsAllowInsecure": true,
    "v2rRoutingStrategy": "AsIs",
    "configExpiryTimestamp": 0,
    "isConfigLock": true,
    "customDns2": "",
    "v2rKcpHeaderType": "none"
}

PAYLOAD
}


case "$1" in
	"-m"|"-i")
		_mostrar
		;;
	"-p"|"-j")
		_payload
		;;
	*)
		echo "Uso: $0 [-m | -p] <link>"
		echo "  -m|-i: Mostrar informações extraídas do link"
		echo "  -p|-j: Gerar payload JSON com as informações extraídas do link"
		exit 1
		;;
esac
