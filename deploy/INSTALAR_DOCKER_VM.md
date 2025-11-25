# 🐳 Instalar Docker na VM do Google Cloud

## Método Rápido (Recomendado)

Execute estes comandos na sua VM:

```bash
# Instalar Docker usando script oficial
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar seu usuário ao grupo docker
sudo usermod -aG docker $USER

# Ativar as permissões (ou faça logout/login)
newgrp docker

# Verificar instalação
docker --version
docker compose version

# Testar Docker
docker run hello-world
```

## Método Manual (Se o método rápido não funcionar)

```bash
# 1. Atualizar sistema
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 2. Adicionar repositório oficial do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Instalar Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# 5. Ativar permissões
newgrp docker

# 6. Verificar
docker --version
docker compose version
```

## ⚠️ Problemas Comuns

### "docker: command not found"
- Execute `newgrp docker` ou faça logout/login
- Se ainda não funcionar, use `sudo docker` temporariamente

### "Permission denied"
- Execute: `sudo usermod -aG docker $USER`
- Depois: `newgrp docker` ou logout/login

### Testar sem permissões
```bash
sudo docker run hello-world
```

