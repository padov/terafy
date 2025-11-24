-- Script para aumentar o limite de conexões do PostgreSQL
-- Execute este script conectado ao banco 'postgres' como superuser

-- 1. Verifica o limite atual
SHOW max_connections;

-- 2. Aumenta o limite para 200 (ajuste conforme necessário)
-- NOTA: Para mudanças permanentes, edite postgresql.conf
-- Para mudanças temporárias (até reiniciar), use:
ALTER SYSTEM SET max_connections = 200;

-- 3. Recarrega a configuração (sem reiniciar)
SELECT pg_reload_conf();

-- 4. Verifica o novo limite
SHOW max_connections;

