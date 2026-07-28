#!/bin/bash
# MAUVADAO
# VER: 1.0.4
# HORAS: ter 21 abr 2026 13:07:56 -03
# Gera chave SSH e adiciona no GitHub
# Configura a conexao ja no ~/.ssh/config
# https://github.com/settings/keys

# Testa conexao com github.
testGit() {
    ssh -o StrictHostKeyChecking=no -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

nome="$1"
comentario="$2"

[[ -z "$nome" || -z "$comentario" ]] && {
    echo "Uso: $0 <nome> <comentario>"
    exit 1
}

# Criar chave SSH.
ssh-keygen -t rsa -b 4096 -C "$comentario" -N "" -f "$HOME/.ssh/${nome}" || {
    echo "Erro ao gerar a chave SSH."
    exit 1
}

# Iniciar ssh-agent e adicionar chave.
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/${nome}"

# Criar ~/.ssh/config.
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "" >> ~/.ssh/config
cat <<EOF >> ~/.ssh/config
# Configuração GitHub.
Host git
    HostName github.com
    User git
    IdentityFile ~/.ssh/${nome}
    IdentitiesOnly yes
EOF

chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/ssh_vps
chmod 644 ~/.ssh/ssh_vps.pub

echo
# Verificar se xclip está instalado.
if ! command -v xclip >/dev/null 2>&1; then
    echo "Xclip não está instalado. Instalando..."
    apt install -y xclip
fi

echo ''
# Copiar chave pública.
cat "$HOME/.ssh/${nome}.pub" | xclip -sel clip >/dev/null 2>&1 || {
clear
echo "Copie a chave .pub: $HOME/.ssh/${nome}.pub"
echo ''
cat "$HOME/.ssh/${nome}.pub"
echo
}

echo "Entre no site: https://github.com/settings/keys"
echo "Adicione o conteúdo da chave: ~/.ssh/${nome}.pub"
echo ""
sleep 5

# Testar conexão até dar certo
while true; do
    if testGit; then
        echo -e "\e[1;32mConexão bem sucedida com GitHub.\e[0m"
	echo -e "\e[1;37mAdd sua key: https://github.com/mauvadao4g/Mauvadao-tools/settings/keys\e[0m"
        exit 0
    else
        echo -e "\e[1;33mAguardando... \e[1;31mtente adicionar a chave no GitHub se não adicionou ainda.\e[0m"
        sleep 5
    fi
done
