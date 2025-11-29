-- migrate:up

-- Insere o template padrão do sistema (disponível para todos os terapeutas)
-- Este template é criado automaticamente e fica disponível para todos os terapeutas
-- Caso precise recriar, execute: make seed-anamnesis-template
INSERT INTO anamnesis_templates (
    therapist_id,
    name,
    description,
    category,
    is_default,
    is_system,
    structure
)
SELECT
    NULL, -- NULL = template do sistema (disponível para todos)
    'Anamnese Padrão - Adulto',
    'Template completo baseado em boas práticas clínicas. Cobre todos os aspectos fundamentais para uma avaliação inicial completa do paciente.',
    'adult',
    FALSE, -- Não é padrão por padrão, terapeuta pode escolher
    TRUE,  -- Template do sistema (não pode ser deletado)
    '{
        "version": "1.0",
        "metadata": {
            "name": "Anamnese Padrão - Adulto",
            "description": "Template completo baseado em boas práticas clínicas",
            "category": "adult"
        },
        "sections": [
            {
                "id": "demographic",
                "title": "Dados Demográficos",
                "order": 1,
                "fields": [
                    {
                        "id": "naturalidade",
                        "type": "text",
                        "label": "Naturalidade",
                        "required": false,
                        "order": 1,
                        "placeholder": "Cidade onde nasceu"
                    },
                    {
                        "id": "nacionalidade",
                        "type": "text",
                        "label": "Nacionalidade",
                        "required": false,
                        "order": 2,
                        "default_value": "Brasileira"
                    },
                    {
                        "id": "religiao",
                        "type": "text",
                        "label": "Religião/Espiritualidade",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "residencia",
                        "type": "text",
                        "label": "Com quem reside",
                        "required": false,
                        "order": 4,
                        "placeholder": "Ex: Sozinho, com família, amigos..."
                    },
                    {
                        "id": "composicao_familiar",
                        "type": "textarea",
                        "label": "Composição Familiar",
                        "required": false,
                        "order": 5,
                        "placeholder": "Descreva a composição da família..."
                    }
                ]
            },
            {
                "id": "chief_complaint",
                "title": "Queixa Principal",
                "order": 2,
                "fields": [
                    {
                        "id": "description",
                        "type": "textarea",
                        "label": "Descrição da Queixa",
                        "required": true,
                        "order": 1,
                        "placeholder": "Qual o motivo que trouxe você à terapia?",
                        "validation": {
                            "min_length": 10,
                            "max_length": 2000
                        }
                    },
                    {
                        "id": "started_when",
                        "type": "text",
                        "label": "Quando começou?",
                        "required": false,
                        "order": 2,
                        "placeholder": "Ex: Há 3 meses, desde a infância..."
                    },
                    {
                        "id": "frequency",
                        "type": "select",
                        "label": "Frequência",
                        "required": false,
                        "order": 3,
                        "options": [
                            {"value": "daily", "label": "Diária"},
                            {"value": "weekly", "label": "Semanal"},
                            {"value": "monthly", "label": "Mensal"},
                            {"value": "sporadic", "label": "Esporádica"},
                            {"value": "constant", "label": "Constante"}
                        ]
                    },
                    {
                        "id": "intensity",
                        "type": "slider",
                        "label": "Intensidade (0-10)",
                        "required": false,
                        "order": 4,
                        "min": 0,
                        "max": 10,
                        "default_value": 5,
                        "show_value": true,
                        "labels": {
                            "min": "Nenhum",
                            "max": "Máximo"
                        }
                    },
                    {
                        "id": "triggers",
                        "type": "textarea",
                        "label": "Fatores Desencadeantes",
                        "required": false,
                        "order": 5,
                        "placeholder": "O que desencadeia ou piora os sintomas?"
                    },
                    {
                        "id": "attempted_solutions",
                        "type": "textarea",
                        "label": "O que já tentou fazer?",
                        "required": false,
                        "order": 6,
                        "placeholder": "Tratamentos anteriores, estratégias de enfrentamento..."
                    }
                ]
            },
            {
                "id": "medical_history",
                "title": "Histórico Médico",
                "order": 3,
                "fields": [
                    {
                        "id": "current_diseases",
                        "type": "textarea",
                        "label": "Doenças Atuais",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "previous_diseases",
                        "type": "textarea",
                        "label": "Doenças Prévias",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "surgeries",
                        "type": "textarea",
                        "label": "Cirurgias Realizadas",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "allergies",
                        "type": "textarea",
                        "label": "Alergias",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "hospitalizations",
                        "type": "textarea",
                        "label": "Internações",
                        "required": false,
                        "order": 5
                    },
                    {
                        "id": "current_medical_care",
                        "type": "textarea",
                        "label": "Acompanhamento Médico Atual",
                        "required": false,
                        "order": 6,
                        "placeholder": "Médicos que acompanha, especialidades..."
                    }
                ]
            },
            {
                "id": "psychiatric_history",
                "title": "Histórico Psiquiátrico",
                "order": 4,
                "fields": [
                    {
                        "id": "previous_diagnoses",
                        "type": "textarea",
                        "label": "Diagnósticos Prévios",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "previous_treatments",
                        "type": "textarea",
                        "label": "Tratamentos Anteriores",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "psychiatric_hospitalizations",
                        "type": "textarea",
                        "label": "Internações Psiquiátricas",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "current_medications",
                        "type": "textarea",
                        "label": "Medicações Psiquiátricas Atuais",
                        "required": false,
                        "order": 4,
                        "placeholder": "Nome, dose, horário"
                    },
                    {
                        "id": "psychiatrist",
                        "type": "text",
                        "label": "Médico Psiquiatra",
                        "required": false,
                        "order": 5,
                        "placeholder": "Nome e contato"
                    },
                    {
                        "id": "has_suicide_attempts",
                        "type": "boolean",
                        "label": "Tentativas de Suicídio",
                        "required": false,
                        "order": 6,
                        "default_value": false
                    },
                    {
                        "id": "suicide_attempts_details",
                        "type": "textarea",
                        "label": "Detalhes das Tentativas",
                        "required": false,
                        "order": 7,
                        "conditional": {
                            "field": "has_suicide_attempts",
                            "operator": "equals",
                            "value": true
                        }
                    },
                    {
                        "id": "self_harm",
                        "type": "boolean",
                        "label": "Automutilação",
                        "required": false,
                        "order": 8,
                        "default_value": false
                    },
                    {
                        "id": "substance_use",
                        "type": "textarea",
                        "label": "Uso de Substâncias",
                        "required": false,
                        "order": 9,
                        "placeholder": "Álcool, drogas, frequência, quantidade..."
                    }
                ]
            },
            {
                "id": "family_history",
                "title": "Histórico Familiar",
                "order": 5,
                "fields": [
                    {
                        "id": "mental_illness_family",
                        "type": "textarea",
                        "label": "Doenças Mentais na Família",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "suicide_family_history",
                        "type": "boolean",
                        "label": "Histórico de Suicídio na Família",
                        "required": false,
                        "order": 2,
                        "default_value": false
                    },
                    {
                        "id": "relationship_with_parents",
                        "type": "textarea",
                        "label": "Relacionamento com Pais",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "relationship_with_siblings",
                        "type": "textarea",
                        "label": "Relacionamento com Irmãos",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "family_dynamics",
                        "type": "textarea",
                        "label": "Dinâmica Familiar",
                        "required": false,
                        "order": 5,
                        "placeholder": "Como é a dinâmica familiar? Conflitos, comunicação..."
                    }
                ]
            },
            {
                "id": "development_history",
                "title": "Histórico de Desenvolvimento",
                "order": 6,
                "fields": [
                    {
                        "id": "pregnancy_birth",
                        "type": "textarea",
                        "label": "Gravidez e Parto",
                        "required": false,
                        "order": 1,
                        "placeholder": "Complicações, tipo de parto..."
                    },
                    {
                        "id": "motor_development",
                        "type": "textarea",
                        "label": "Desenvolvimento Motor",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "language_development",
                        "type": "textarea",
                        "label": "Desenvolvimento da Linguagem",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "developmental_milestones",
                        "type": "textarea",
                        "label": "Marcos do Desenvolvimento",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "schooling",
                        "type": "textarea",
                        "label": "Escolarização",
                        "required": false,
                        "order": 5,
                        "placeholder": "Histórico escolar, dificuldades, desempenho..."
                    }
                ]
            },
            {
                "id": "social_life",
                "title": "Vida Social",
                "order": 7,
                "fields": [
                    {
                        "id": "social_circle",
                        "type": "textarea",
                        "label": "Círculo Social",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "friendship_quality",
                        "type": "textarea",
                        "label": "Qualidade das Amizades",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "romantic_relationships",
                        "type": "textarea",
                        "label": "Relacionamentos Amorosos",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "support_network",
                        "type": "textarea",
                        "label": "Rede de Apoio",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "leisure_activities",
                        "type": "textarea",
                        "label": "Atividades de Lazer",
                        "required": false,
                        "order": 5
                    },
                    {
                        "id": "hobbies",
                        "type": "textarea",
                        "label": "Hobbies",
                        "required": false,
                        "order": 6
                    }
                ]
            },
            {
                "id": "professional_academic",
                "title": "Vida Profissional/Acadêmica",
                "order": 8,
                "fields": [
                    {
                        "id": "current_occupation",
                        "type": "text",
                        "label": "Ocupação Atual",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "professional_satisfaction",
                        "type": "textarea",
                        "label": "Satisfação Profissional",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "work_conflicts",
                        "type": "textarea",
                        "label": "Conflitos no Trabalho",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "professional_history",
                        "type": "textarea",
                        "label": "Histórico Profissional",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "academic_situation",
                        "type": "textarea",
                        "label": "Situação Acadêmica (se estudante)",
                        "required": false,
                        "order": 5
                    }
                ]
            },
            {
                "id": "life_habits",
                "title": "Hábitos de Vida",
                "order": 9,
                "fields": [
                    {
                        "id": "sleep_pattern",
                        "type": "textarea",
                        "label": "Padrão de Sono",
                        "required": false,
                        "order": 1,
                        "placeholder": "Horas de sono, qualidade, insônia..."
                    },
                    {
                        "id": "diet",
                        "type": "textarea",
                        "label": "Alimentação",
                        "required": false,
                        "order": 2,
                        "placeholder": "Padrão alimentar, restrições, compulsões..."
                    },
                    {
                        "id": "physical_activity",
                        "type": "textarea",
                        "label": "Atividade Física",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "technology_use",
                        "type": "textarea",
                        "label": "Uso de Tecnologia/Internet",
                        "required": false,
                        "order": 4
                    },
                    {
                        "id": "daily_routine",
                        "type": "textarea",
                        "label": "Rotina Diária",
                        "required": false,
                        "order": 5
                    }
                ]
            },
            {
                "id": "sexuality",
                "title": "Sexualidade",
                "order": 10,
                "fields": [
                    {
                        "id": "sexual_orientation",
                        "type": "text",
                        "label": "Orientação Sexual",
                        "required": false,
                        "order": 1,
                        "sensitive": true
                    },
                    {
                        "id": "active_sex_life",
                        "type": "boolean",
                        "label": "Vida Sexual Ativa",
                        "required": false,
                        "order": 2,
                        "sensitive": true
                    },
                    {
                        "id": "sexual_satisfaction",
                        "type": "textarea",
                        "label": "Satisfação Sexual",
                        "required": false,
                        "order": 3,
                        "sensitive": true
                    },
                    {
                        "id": "sexuality_issues",
                        "type": "textarea",
                        "label": "Questões Relacionadas",
                        "required": false,
                        "order": 4,
                        "sensitive": true
                    }
                ]
            },
            {
                "id": "legal_aspects",
                "title": "Aspectos Legais",
                "order": 11,
                "fields": [
                    {
                        "id": "ongoing_legal_processes",
                        "type": "textarea",
                        "label": "Processos Judiciais em Andamento",
                        "required": false,
                        "order": 1,
                        "sensitive": true
                    },
                    {
                        "id": "criminal_history",
                        "type": "textarea",
                        "label": "Histórico Criminal",
                        "required": false,
                        "order": 2,
                        "sensitive": true
                    },
                    {
                        "id": "custody_family_issues",
                        "type": "textarea",
                        "label": "Questões de Guarda/Família",
                        "required": false,
                        "order": 3,
                        "sensitive": true
                    }
                ]
            },
            {
                "id": "expectations",
                "title": "Expectativas",
                "order": 12,
                "fields": [
                    {
                        "id": "treatment_expectations",
                        "type": "textarea",
                        "label": "O que espera do tratamento?",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "personal_goals",
                        "type": "textarea",
                        "label": "Objetivos Pessoais",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "session_availability",
                        "type": "textarea",
                        "label": "Disponibilidade para Sessões",
                        "required": false,
                        "order": 3
                    },
                    {
                        "id": "commitment",
                        "type": "textarea",
                        "label": "Comprometimento",
                        "required": false,
                        "order": 4,
                        "placeholder": "Como avalia seu comprometimento com o tratamento?"
                    }
                ]
            },
            {
                "id": "observations",
                "title": "Observações Gerais",
                "order": 13,
                "fields": [
                    {
                        "id": "therapist_impressions",
                        "type": "textarea",
                        "label": "Impressões do Terapeuta",
                        "required": false,
                        "order": 1
                    },
                    {
                        "id": "relevant_aspects",
                        "type": "textarea",
                        "label": "Aspectos Relevantes Não Categorizados",
                        "required": false,
                        "order": 2
                    },
                    {
                        "id": "custom_notes",
                        "type": "textarea",
                        "label": "Notas Adicionais",
                        "required": false,
                        "order": 3
                    }
                ]
            }
        ],
        "settings": {
            "allow_patient_fill": false,
            "require_completion": false,
            "show_progress": true
        }
    }'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM anamnesis_templates 
    WHERE is_system = TRUE AND name = 'Anamnese Padrão - Adulto'
);

-- migrate:down

-- Remove o template padrão do sistema
DELETE FROM anamnesis_templates 
WHERE is_system = TRUE AND name = 'Anamnese Padrão - Adulto';

