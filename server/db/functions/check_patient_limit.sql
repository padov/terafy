-- Function: check_patient_limit
-- Descrição: Verifica se o terapeuta pode criar um novo paciente baseado no limite do plano
-- Conta apenas pacientes com status 'active' ou 'evaluated'
-- Se não houver plano ativo, usa o plano Free (limite de 10 pacientes)
--
-- Quando usar: Trigger BEFORE INSERT na tabela patients

CREATE OR REPLACE FUNCTION check_patient_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_patient_limit INTEGER;
  v_current_count INTEGER;
  v_plan_name VARCHAR(100);
BEGIN
  -- Busca o limite do plano ativo do terapeuta
  SELECT 
    COALESCE(p.patient_limit, 10),
    COALESCE(p.name, 'Free')
  INTO 
    v_patient_limit,
    v_plan_name
  FROM therapists t
  LEFT JOIN plan_subscriptions ps ON t.id = ps.therapist_id 
    AND ps.is_active = true 
    AND ps.end_date >= NOW()
  LEFT JOIN plans p ON ps.plan_id = p.id
  WHERE t.id = NEW.therapist_id
  ORDER BY ps.created_at DESC
  LIMIT 1;

  -- Se não encontrou plano, usa o padrão Free (10 pacientes)
  IF v_patient_limit IS NULL THEN
    v_patient_limit := 10;
    v_plan_name := 'Free';
  END IF;

  -- Conta pacientes ativos do terapeuta (apenas active e evaluated)
  SELECT COUNT(*)
  INTO v_current_count
  FROM patients
  WHERE therapist_id = NEW.therapist_id
    AND status IN ('active', 'evaluated');

  -- Verifica se excede o limite
  -- Nota: Não conta o paciente que está sendo inserido ainda, então verificamos se já está no limite
  IF v_current_count >= v_patient_limit THEN
    RAISE EXCEPTION 
      'Limite de pacientes atingido. Você possui % de % pacientes permitidos no seu plano atual (%). Faça upgrade para adicionar mais pacientes.',
      v_current_count,
      v_patient_limit,
      v_plan_name;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

