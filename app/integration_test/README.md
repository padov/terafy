# Testes Visuais Automatizados - Login

Este diretório contém testes de integração automatizados para a funcionalidade de login, seguindo a seção 1.1 do plano de testes (`plano_testes.md`).

## 📋 Cobertura de Testes

Os testes cobrem todos os 5 cenários da seção 1.1:

1. ✅ **Login com credenciais válidas** - Verifica que o usuário consegue fazer login e é redirecionado
2. ✅ **Login com credenciais inválidas** - Verifica que erros são exibidos corretamente
3. ✅ **Validação de campos obrigatórios** - Testa validações de email e senha
4. ✅ **Redirecionamento após login** - Confirma navegação correta após autenticação
5. ✅ **Persistência de sessão** - Verifica que a sessão permanece após reiniciar o app

## 🚀 Como Executar os Testes

### Pré-requisitos

1. **Backend rodando**: Certifique-se de que o backend está ativo

   ```bash
   make server-dev
   ```

2. **Usuário de teste criado**: Execute o comando para criar o usuário de teste

   ```bash
   make create-test-user
   ```

3. **Dispositivo/Emulador**: Tenha um dispositivo ou emulador conectado
   ```bash
   flutter devices
   ```

### Executando os Testes

#### Opção 1: Executar todos os testes de login

```bash
cd app
flutter test integration_test/login_visual_test.dart --device-id=<DEVICE_ID>
```

Substitua `<DEVICE_ID>` pelo ID do seu dispositivo (ex: `emulator-5554`, `macos`, `chrome`).

#### Opção 2: Executar um teste específico

```bash
flutter test integration_test/login_visual_test.dart --plain-name="1.1.1 - Login with valid credentials"
```

#### Opção 3: Executar com driver (recomendado para CI/CD)

```bash
flutter drive \
  --driver=test_driver/integration_test_driver.dart \
  --target=integration_test/login_visual_test.dart \
  --device-id=<DEVICE_ID>
```

### Exemplos por Plataforma

**Android Emulator:**

```bash
flutter test integration_test/login_visual_test.dart --device-id=emulator-5554
```

**macOS:**

```bash
flutter test integration_test/login_visual_test.dart --device-id=macos
```

**Chrome (Web):**

```bash
flutter test integration_test/login_visual_test.dart --device-id=chrome
```

## 📁 Estrutura de Arquivos

```
integration_test/
├── login_visual_test.dart    # Testes principais do login
├── test_helpers.dart          # Utilitários e helpers para testes
└── README.md                  # Este arquivo

test_driver/
└── integration_test_driver.dart  # Driver para executar os testes
```

## 🔧 Troubleshooting

### Erro: "No devices found"

- Certifique-se de que um emulador/dispositivo está rodando
- Execute `flutter devices` para verificar dispositivos disponíveis
- Inicie um emulador com `flutter emulators --launch <emulator_id>`

### Erro: "Connection refused" ou "Failed to connect to backend"

- Verifique se o backend está rodando em `http://localhost:8080`
- Execute `make server-dev` no diretório raiz do projeto

### Erro: "User not found" ou "Invalid credentials"

- Execute `make create-test-user` para criar o usuário de teste
- Verifique se as credenciais em `test_helpers.dart` estão corretas:
  - Email: `teste@terafy.app.br`
  - Senha: `123456`

### Testes falhando intermitentemente

- Aumente os timeouts nos testes (ex: `Duration(seconds: 10)`)
- Verifique a conexão de rede
- Certifique-se de que o backend não está sobrecarregado

## 📝 Adicionando Novos Testes

Para adicionar novos testes de login:

1. Abra `login_visual_test.dart`
2. Adicione um novo `testWidgets` dentro do grupo apropriado
3. Use os helpers de `IntegrationTestHelpers` para interações
4. Siga o padrão AAA (Arrange, Act, Assert)

Exemplo:

```dart
testWidgets('Novo cenário de teste', (tester) async {
  // Arrange: Configurar o estado inicial
  await IntegrationTestHelpers.pumpApp(tester);

  // Act: Executar a ação
  await IntegrationTestHelpers.tap(tester, find.text('Botão'));

  // Assert: Verificar o resultado
  expect(find.text('Resultado Esperado'), findsOneWidget);
});
```

## 🎯 Próximos Passos

Após validar os testes de login, os próximos módulos a serem testados são:

- [ ] 1.2 - Cadastro de Terapeuta
- [ ] 1.3 - Logout
- [ ] 2.1 - Home/Dashboard
- [ ] 3.x - Pacientes
- [ ] 4.x - Agenda/Agendamentos
- [ ] 5.x - Sessões
- [ ] 6.x - Financeiro

## 📚 Recursos Adicionais

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Flutter Test Documentation](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
