# Dockerfile para o servidor Terafy
# Build multi-stage para otimizar tamanho da imagem
# Contexto: raiz do projeto (terafy/) - definido no docker-compose.yml

# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Estrutura final desejada:
#   /app/server/  (código do servidor)  
#   /app/common/  (código comum)

# Estratégia: Copiar tudo primeiro, depois instalar dependências
# Isso evita problemas com path dependencies e cache do host

# Passo 1: Copia TODO o código primeiro
COPY common/ ./common/
COPY server/ ./server/

# Passo 2: Instala dependências do common primeiro
WORKDIR /app/common
RUN dart pub get

# Passo 3: Instala dependências do server (agora ../common existe e está resolvido)
WORKDIR /app/server
RUN dart pub get

# Passo 4: Compila o servidor
RUN dart compile exe bin/server.dart -o server

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia apenas o binário compilado
COPY --from=build /app/server/server .

EXPOSE 8080
ENV PORT=8080

CMD ["./server"]
