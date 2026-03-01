#!/bin/bash
# Script para gerar a imagem ISO do Cloud-Init no WSL

echo "Verificando dependências no sistema..."
if ! command -v genisoimage &> /dev/null
then
    echo "A ferramenta genisoimage não foi encontrada. Iniciando instalação..."
    sudo apt update && sudo apt install -y genisoimage
fi

echo "Empacotando configurações e gerando seed.iso..."
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data

echo "✅ Arquivo seed.iso gerado com sucesso! Você já pode inseri-lo no drive de CD virtual do seu VirtualBox."