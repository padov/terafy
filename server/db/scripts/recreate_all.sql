-- ============================================
-- Script para Recriar Todas as Functions, Triggers e Policies
-- ============================================
-- Este script deve ser executado ao final de cada migração
-- para garantir que todas as functions, triggers e policies
-- estejam sincronizadas e atualizadas.
--
-- Ordem de execução:
-- 1. Functions (precisam existir antes dos triggers)
-- 2. Triggers (dependem das functions)
-- 3. Policies (dependem das tabelas)
-- ============================================

-- Configuração
DO $$
DECLARE
  v_schema_name TEXT := 'public';
  v_owner_name TEXT := current_user;
BEGIN
  -- Log início
  RAISE NOTICE 'Iniciando recriação de functions, triggers e policies para owner: %', v_owner_name;
END $$;

-- ============================================
-- PARTE 1: LIMPAR OBJETOS EXISTENTES
-- ============================================

-- Remove todos os triggers primeiro (dependem de functions)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT trigger_name, event_object_table
    FROM information_schema.triggers
    WHERE trigger_schema = 'public'
      AND event_object_table NOT IN ('schema_migrations') -- Não remove trigger de migrations
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', r.trigger_name, r.event_object_table);
    RAISE NOTICE 'Trigger removido: %', r.trigger_name;
  END LOOP;
END $$;

-- Remove todas as functions do owner (exceto system functions)
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT proname, oidvectortypes(proargtypes) as args
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proowner = (SELECT oid FROM pg_roles WHERE rolname = current_user)
      AND proname NOT LIKE 'pg_%' -- Não remove system functions
      AND proname NOT LIKE 'sql_%'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s(%s) CASCADE', r.proname, COALESCE(r.args, ''));
    RAISE NOTICE 'Function removida: %', r.proname;
  END LOOP;
END $$;

-- ============================================
-- PARTE 2: RECRIAR FUNCTIONS
-- ============================================

-- Nota: As functions serão carregadas de arquivos externos
-- Este é um template - você precisa incluir os arquivos das pastas functions/
-- 
-- Exemplo de como incluir:
-- \i functions/ft_after_appointment.sql
-- \i functions/check_appointment_overlap.sql
-- etc...

RAISE NOTICE 'Functions serão recriadas via \i commands ou programaticamente';

-- ============================================
-- PARTE 3: RECRIAR TRIGGERS
-- ============================================

-- Nota: Os triggers serão carregados de arquivos externos
-- da pasta triggers/

RAISE NOTICE 'Triggers serão recriados via \i commands ou programaticamente';

-- ============================================
-- PARTE 4: RECRIAR POLICIES
-- ============================================

-- Remove todas as policies existentes primeiro
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN 
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename);
    RAISE NOTICE 'Policy removida: %', r.policyname;
  END LOOP;
END $$;

-- Nota: As policies serão recarregadas de arquivos externos
-- da pasta policies/

RAISE NOTICE 'Policies serão recriadas via \i commands ou programaticamente';

-- ============================================
-- FINALIZAÇÃO
-- ============================================

DO $$
BEGIN
  RAISE NOTICE 'Recriação concluída com sucesso!';
END $$;

