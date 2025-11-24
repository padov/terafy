# Guia de Teste - Login no App Flutter

## Pré-requisitos

1. ✅ Backend rodando em `http://localhost:8080`
2. ✅ Usuário de teste criado no banco de dados
3. ✅ Migrations executadas
4. ✅ App Flutter configurado

## Credenciais de Teste

- **Email**: `teste@terafy.com`
- **Senha**: `senha123`

## Passo a Passo para Testar

### 1. Criar o usuário de teste (se ainda não criou)

```bash
# Método 1: Via script Dart (recomendado)
make create-test-user

# Método 2: Via SQL
psql -h localhost -U postgres -d terafy_db -f server/db/scripts/create_test_user.sql
```

### 2. Iniciar o backend

```bash
# Terminal 1 - Backend
make server
# ou
cd server && dart run bin/server.dart
```

Você deve ver:
```
 _____                          ____                            
|_   _|__ _ __ __ _ ___ _   _  / ___|  ___ _ ____   _____ _ __ 
...
Servidor rodando em http://0.0.0.0:8080
```

### 3. Testar a API diretamente (opcional, para validar)

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@terafy.com",
    "password": "senha123"
  }'
```

Deve retornar algo como:
```json
{
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "teste@terafy.com",
    "role": "therapist",
    ...
  }
}
```

### 4. Executar o app Flutter

```bash
# Terminal 2 - Flutter App
cd app
flutter run
```

**Nota importante sobre URLs:**
- O app detecta automaticamente a plataforma:
  - **iOS Simulator**: `http://localhost:8080`
  - **Android Emulator**: `http://10.0.2.2:8080`
  - **Web**: `http://localhost:8080`

### 5. Testar o login no app

1. Abra o app Flutter
2. Navegue até a tela de login
3. Digite:
   - Email: `teste@terafy.com`
   - Senha: `senha123`
4. Clique em "Entrar" ou "Login"

### 6. Verificar o comportamento esperado

**Cenário de Sucesso:**
- ✅ Loading aparece durante a requisição
- ✅ Token JWT é salvo no SecureStorage
- ✅ Navega para a tela Home
- ✅ Não mostra erros

**Cenário de Erro (credenciais inválidas):**
- ✅ Mostra mensagem de erro: "Credenciais inválidas"
- ✅ Permanece na tela de login

**Cenário de Erro (conexão):**
- ✅ Mostra mensagem de erro de conexão
- ✅ Permanece na tela de login

## Verificar se o token foi salvo

No app Flutter, você pode verificar os logs do console. O token deve ser salvo via `SecureStorageService`.

## Troubleshooting

### Erro: "Connection refused"
- Verifique se o backend está rodando na porta 8080
- Verifique se não há firewall bloqueando
- **Android**: Certifique-se de usar `10.0.2.2` em vez de `localhost`

### Erro: "Timeout"
- Verifique a conexão de rede
- No iOS Simulator, use `localhost`
- No Android Emulator, use `10.0.2.2` (já configurado automaticamente)

### Erro: "401 Unauthorized"
- Verifique se o usuário existe no banco
- Verifique se a senha está correta
- Execute `make create-test-user` novamente

### Erro: "JSON decode error"
- Verifique se o backend está retornando JSON válido
- Verifique os logs do backend

## Logs Úteis

No app Flutter, os logs aparecem com tags:
- `AuthAPI Response` - Resposta da API
- `AuthAPI DioException` - Erros de rede
- `LoginBloc` - Eventos do Bloc

No backend, os logs aparecem automaticamente via `logRequests()` middleware.

## ✅ Alterações Realizadas no App

1. ✅ Endpoint ajustado para `/auth/login`
2. ✅ Tratamento de erros aprimorado (401, 400, 403)
3. ✅ AuthResultModel mapeia corretamente `auth_token` e `user`
4. ✅ LoginBloc reativado e funcional
5. ✅ StorageService unificado com SecureStorageService
6. ✅ URL base configurada automaticamente por plataforma (Android/iOS/Web)

## 🚀 Próximos Passos

Após testar o login com sucesso:

### Passo 3: Verificar Token nas Requisições
- Verificar se o token está sendo enviado automaticamente nas requisições subsequentes
- Testar uma rota protegida (ex: `GET /therapists`)

### Passo 4: Criar Therapist Completo
- Após login, criar o therapist completo via `POST /therapists`
- Vincular o `user_id` ao therapist criado
- Buscar dados completos do terapeuta após login

### Passo 5: Implementar Logout
- Criar endpoint `/auth/logout` (opcional - pode ser só limpar token no cliente)
- Limpar token do SecureStorage
- Redirecionar para tela de login

### Passo 6: Melhorar Dados do Usuário
- Buscar dados completos do therapist após login usando `account_id`
- Atualizar `ClientModel` com dados completos do terapeuta
- Mostrar nome completo do terapeuta na Home

### Passo 7: Refresh Token (Opcional)
- Implementar refresh token separado
- Renovar token automaticamente antes de expirar
- Tratar token expirado e fazer refresh automático

### Passo 8: Validação e Segurança
- Adicionar validação de email no frontend
- Adicionar validação de senha forte
- Implementar "Esqueci minha senha"
- Adicionar rate limiting no backend

### Passo 9: Testes Automatizados
- Criar testes de integração para o fluxo de login
- Testar diferentes cenários (sucesso, erro, timeout)
- Testar persistência do token

### Passo 10: Melhorias de UX
- Adicionar loading state melhor
- Adicionar feedback visual de sucesso
- Implementar "Lembrar-me" (salvar email)
- Melhorar mensagens de erro

---

**Boa sorte com os testes! 🎉**



Execute todos os testes da feature auth (unitários e de integração) e me mostre:
1. Resumo dos resultados (quantos passaram/falharam)
2. Detalhes de qualquer falha encontrada
3. Se houver falhas, corrija os problemas e execute novamente até que todos passem