-- Script para criar usuário de teste
-- Execute este script após executar as migrations
-- 
-- Credenciais de teste:
-- Email: teste@terafy.com
-- Senha: senha123
--
-- O hash SHA-256 de 'senha123' é: ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f

-- Criar usuário de teste
DELETE FROM users WHERE email = 'teste@terafy.com';
INSERT INTO users (email, password_hash, role, status, email_verified)
VALUES (
  'teste@terafy.com',
  '55a5e9e78207b4df8699d60886fa070079463547b095d1a05bc719bb4e6cd251', -- hash SHA-256 de 'senha123'
  'therapist',
  'active',
  true
)
ON CONFLICT (email) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  status = 'active';

-- Verificar usuário criado
SELECT id, email, role, account_type, account_id, status, email_verified, created_at
FROM users 
WHERE email = 'teste@terafy.com';

