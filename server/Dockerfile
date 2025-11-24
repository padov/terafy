# Use a imagem oficial do Dart
FROM dart:stable AS build

WORKDIR /app

# Copia os arquivos de dependências
COPY pubspec.* ./
COPY ../common/pubspec.yaml ../common/
RUN dart pub get

# Copia o código fonte
COPY . .
COPY ../common ../common

# Compila o servidor
RUN dart compile exe bin/server.dart -o server

# Imagem de produção
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia o binário compilado
COPY --from=build /app/server .

# Expõe a porta
EXPOSE 8080

# Define variáveis de ambiente padrão
ENV PORT=8080

# Comando para executar o servidor
CMD ["./server"]