# Dockerfile para PostgreSQL de desenvolvimento local
# Uso: docker build -f docker/Dockerfile.postgres -t terafy-postgres-local .
#      docker run -d --name terafy-postgres-local -p 5432:5432 terafy-postgres-local

FROM postgres:16-alpine

# Variáveis de ambiente padrão para desenvolvimento
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=mysecretpassword
ENV POSTGRES_DB=terafy_db

# Configurações do PostgreSQL para desenvolvimento
# - max_connections: máximo de conexões simultâneas
# - shared_buffers: memória compartilhada para cache
# - idle_in_transaction_session_timeout: encerra conexões idle em transação após 5 minutos
# - statement_timeout: encerra queries muito longas após 30 segundos
RUN echo "max_connections = 200" >> /usr/local/share/postgresql/postgresql.conf.sample && \
    echo "shared_buffers = 256MB" >> /usr/local/share/postgresql/postgresql.conf.sample && \
    echo "idle_in_transaction_session_timeout = 300000" >> /usr/local/share/postgresql/postgresql.conf.sample && \
    echo "statement_timeout = 30000" >> /usr/local/share/postgresql/postgresql.conf.sample

# Expõe a porta padrão do PostgreSQL
EXPOSE 5432

# O PostgreSQL já tem um entrypoint padrão que inicializa o banco
# Não precisa de CMD adicional

