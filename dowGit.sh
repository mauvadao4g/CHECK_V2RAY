#!/bin/bash
#  MAUVADAO
#  VER 1.0.5
#  DATA: /02/2024
#  BAIXA OS ARQUIVOS DO GITHUB

clear

# VERIFICAR CONEXAO COM GITHUB
check_github_connection() {
    response=$(ssh -T git@github.com 2>&1)

    [[ $response == *"You've successfully authenticated"* ]] && {
        echo -e "\e[1;32mConectado com GitHub\e[0m"
    } || {
        echo -e "\e[1;31mFalha ao conectar\e[0m"
        exit 1
    }
}

# Chama a função para testar a conexão
check_github_connection

# Função para exibir mensagens coloridas
print_msg() {
    case $1 in
        "error") echo -e "\e[1;31m$2\e[m" ;;   # Vermelho
        "success") echo -e "\e[1;32m$2\e[m" ;; # Verde
        "warning") echo -e "\e[1;33m$2\e[m" ;; # Amarelo
        "info") echo -e "\e[1;36m$2\e[m" ;;    # Ciano
        *) echo "$2" ;;                        # Sem cor
    esac
}

# Função para enviar uma mensagem de texto no Telegram
_enviar_msg() {
    local token="$1"
    local chat_id="$2"
    local text="$3"

    response=$(curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d "chat_id=$chat_id" \
        -d "text=$text" \
        -d "parse_mode=HTML")

    echo "$response" | grep -q '"ok":true'
    return $?
}

# Pegando o nome da Pasta atual
base="$(basename "$(pwd)")"

# GERANDO TOKENS
token_file="$HOME/tokens.sh"

if [ ! -f "$token_file" ]; then
    echo -e "\e[1;31mToken não encontrado. Criando novo token...\e[0m"
    echo -ne '\e[1;37m'
    read -p "Token Telegram: " TOKEN
    read -p "ChatId: " CHATID
    echo -ne '\e[0m'

    cat <<EOF > "$token_file"
#!/bin/bash
# Tokens do telegram
TOKEN=$TOKEN
CHATID=$CHATID
EOF

    chmod +x "$token_file"
    source "$token_file"
else
    source "$token_file"
fi

# PEGANDO HORÁRIO
horas=$(date '+%H:%M:%S')

# PARTE PRINCIPAL DO DOWNLOAD
print_msg 'warning' 'Baixando os arquivos'
git pull

if [[ $? -eq 0 ]]; then
    sleep 1
    clear
    echo "MauDaVpn" | figlet
    print_msg 'info' '######################'
    print_msg 'info' " Baixado com Sucesso "
    print_msg 'info' '######################'
    cat ver[0-9]* | tail -n 7
else
    clear
    print_msg 'error' "Algo deu errado"
    exit 1
fi

# ENVIANDO MENSAGEM AO TELEGRAM
MSG="$(
echo "#############################"
echo "        DOWNLOAD              "
echo "#############################"
echo "User: $(whoami)"
echo "Hora: $horas"
echo "Repo: $base"
cat ver[0-9]* | tail -n 7
echo "#############################"
)"

_enviar_msg "$TOKEN" "$CHATID" "$MSG" >/dev/null 2>&1

# Verificar se foi enviado corretamente
status_msg=$?
if [ $status_msg -eq 0 ]; then
    echo -e "\e[1;32mSend: Enviada\e[0m"
else
    echo -e "\e[1;31mSend: Algo deu errado\e[0m"
    exit 1
fi
