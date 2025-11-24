# Configuração de Variáveis de Ambiente

O servidor usa arquivo `.env` para configurações sensíveis.

## Setup Inicial

1. Copie o arquivo `.env.example` para `.env`:
```bash
cp .env.example .env
```

2. Edite o arquivo `.env` e preencha os valores:
```bash
# JWT Secret Key - Use uma chave forte e aleatória (mínimo 32 caracteres)
JWT_SECRET_KEY=sua-chave-secreta-super-segura-aqui-mude-em-producao

# JWT Expiration (em dias)
JWT_EXPIRATION_DAYS=7
```

## Variáveis Disponíveis

- `JWT_SECRET_KEY`: Chave secreta para assinar tokens JWT (obrigatório em produção)
- `JWT_EXPIRATION_DAYS`: Dias até o token expirar (padrão: 7)

## Segurança

⚠️ **IMPORTANTE:**
- O arquivo `.env` está no `.gitignore` e **NUNCA** deve ser commitado
- Use uma chave secreta forte e única para cada ambiente (dev, staging, prod)
- Em produção, considere usar um gerenciador de secrets (AWS Secrets Manager, HashiCorp Vault, etc.)

## Como Gerar uma Chave Secreta Segura

Você pode gerar uma chave segura usando:

```bash
# Linux/Mac
openssl rand -base64 64

# Ou usando Python
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

