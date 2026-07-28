#!/usr/bin/env bash
# MAUVADAO
# VER: 1.0.0
# DATA: dom 07 jun 2026 18:54:03 -03


# AUTO_BKP.SH
#
# Uso:
#   auto_bkp.sh -c nome_pasta
#       Compacta, gera hash e envia para drive:AUTO_BKP
#
#   auto_bkp.sh -d nome_pasta
#       Descompacta nome_pasta.tar.gz
#
#   auto_bkp.sh -t nome_pasta
#       Testa integridade do .tar.gz sem extrair
#
# Exemplo:
#   auto_bkp.sh -c repositorios
#   auto_bkp.sh -d repositorios
#   auto_bkp.sh -t repositorios

set -euo pipefail

REMOTE="drive:AUTO_BKP"

# Arquivos e pastas a excluir do backup
exclude=(
    ".git"
    ".venv"
     "node_modules"
     "__pycache__"
     "*.log"
    "*.tmp"
    ".cache"
    # Adicione mais arquivos ou pastas para excluir
)

status() {
    printf "%-25s OK\n" "$1"
}

erro() {
    echo
    echo "[ERRO] $1"
    exit 1
}

compactar() {
    local DIR="$1"

    [[ -d "$DIR" ]] || erro "Pasta nao encontrada: $DIR"

    local ARQ="${DIR%/}.tar.gz"

    echo
    echo "=========================================="
    echo "INICIANDO BACKUP"
    echo "=========================================="
    echo

    local TAR_EXCLUDES=()

    for item in "${exclude[@]}"; do
        TAR_EXCLUDES+=(--exclude="$item")
    done

    tar \
        "${TAR_EXCLUDES[@]}" \
        -cf - "$DIR" | gzip -1 > "$ARQ"

    status "Compactando"

    sha256sum "$ARQ" > "${ARQ}.sha256"

    status "Gerando HASH"

    gzip -t "$ARQ"

    status "Testando integridade"

    rclone copy "$ARQ" "$REMOTE" --progress

    status "Enviando backup"

    rclone copy "${ARQ}.sha256" "$REMOTE" --progress

    status "Enviando HASH"

    echo
    echo "=========================================="
    echo "BACKUP FINALIZADO COM SUCESSO"
    echo "=========================================="
    echo
    echo "Arquivo : $ARQ"
    echo "Hash    : ${ARQ}.sha256"
    echo "Destino : $REMOTE"
    echo

    echo "Itens excluidos:"
    printf ' - %s\n' "${exclude[@]}"
    echo
}

descompactar() {
    local NOME="$1"
    local ARQ="${NOME}.tar.gz"

    [[ -f "$ARQ" ]] || erro "Arquivo nao encontrado: $ARQ"

    echo
    tar -xzf "$ARQ"

    status "Extracao concluida"
    echo
}

testar() {
    local NOME="$1"
    local ARQ="${NOME}.tar.gz"

    [[ -f "$ARQ" ]] || erro "Arquivo nao encontrado: $ARQ"

    gzip -t "$ARQ"

    status "Teste GZIP"

    if [[ -f "${ARQ}.sha256" ]]; then
        sha256sum -c "${ARQ}.sha256" >/dev/null 2>&1
        status "Verificacao SHA256"
    else
        echo "[AVISO] Arquivo .sha256 nao encontrado"
    fi

    echo
    echo "Arquivo validado com sucesso."
    echo
}

help() {
cat << EOF

Uso:
  auto_bkp.sh -c nome_pasta
      Compacta, gera hash e envia para $REMOTE

  auto_bkp.sh -d nome_pasta
      Descompacta nome_pasta.tar.gz

  auto_bkp.sh -t nome_pasta
      Testa integridade do arquivo sem extrair

Exemplos:
  auto_bkp.sh -c repositorios
  auto_bkp.sh -d repositorios
  auto_bkp.sh -t repositorios

Itens excluidos atualmente:
$(printf '  - %s\n' "${exclude[@]}")

EOF
exit 0
}

[[ $# -lt 2 ]] && help

case "$1" in
    -c)
        compactar "$2"
        ;;
    -d)
        descompactar "$2"
        ;;
    -t)
        testar "$2"
        ;;
    -h|--help)
        help
        ;;
    *)
        echo "Opcao invalida: $1"
        help
        ;;
esac
