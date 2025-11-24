-- migrate:up

-- Cria usuário específico para a aplicação (não usa postgres superuser)
-- Este usuário tem apenas as permissões necessárias para a aplicação

-- Cria o usuário se não existir
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'terafy_app') THEN
    CREATE USER terafy_app WITH PASSWORD 'terafy_app_password';
  END IF;
END
$$;

-- Permite conexão ao banco
GRANT CONNECT ON DATABASE terafy_db TO terafy_app;

-- Permite uso do schema público
GRANT USAGE ON SCHEMA public TO terafy_app;

-- Permite criar tabelas (para migrations)
GRANT CREATE ON SCHEMA public TO terafy_app;

-- Permite todas as operações nas tabelas existentes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO terafy_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO terafy_app;

-- Permite executar funções existentes
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO terafy_app;

-- Configura permissões padrão para objetos futuros
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO terafy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO terafy_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO terafy_app;

-- Configura timeout de conexões idle para o usuário da aplicação
-- Conexões idle por mais de 5 minutos serão encerradas automaticamente
ALTER ROLE terafy_app SET idle_in_transaction_session_timeout = '5min';

-- Configura statement timeout (opcional - para queries muito longas)
-- ALTER ROLE terafy_app SET statement_timeout = '30s';

-- migrate:down

-- Remove o usuário da aplicação
DROP USER IF EXISTS terafy_app;

