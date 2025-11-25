# Dockerfile apenas para runtime (binário já compilado)
# Use este quando já tiver o binário compilado localmente

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia o binário compilado (vem de fora)
COPY server /app/server

EXPOSE 8080
ENV PORT=8080

CMD ["./server"]

