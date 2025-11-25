#!/bin/bash
# Script para instalar Docker e Docker Compose na VM do Google Cloud

set -e

echo "🐳 Instalando Docker e Docker Compose..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Adicionar repositório oficial do Docker
echo "➕ Adicionando repositório do Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
echo "📥 Instalando Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Adicionar usuário ao grupo docker
echo "👤 Adicionando usuário ao grupo docker..."
sudo usermod -aG docker $USER

# Verificar instalação
echo "✅ Verificando instalação..."
docker --version
docker compose version

echo ""
echo "🎉 Docker instalado com sucesso!"
echo ""
echo "⚠️  IMPORTANTE: Você precisa fazer logout e login novamente para que as permissões do grupo docker funcionem."
echo "   Ou execute: newgrp docker"
echo ""
echo "Para testar sem fazer logout:"
echo "  sudo docker run hello-world"

