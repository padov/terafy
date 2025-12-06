# Prompt para Geração de Testes Flutter

Este documento contém um template de prompt para ser usado sempre que você terminar de implementar uma página/widget Flutter e precisar gerar testes automatizados.

## Como Usar

1. Copie o template da seção "Template do Prompt" abaixo
2. Substitua `[caminho completo do arquivo]` pelo caminho do seu arquivo
3. Cole no chat com a IA
4. A IA analisará o arquivo e gerará os testes automaticamente

---

## Template do Prompt (Versão Simplificada)

````
Preciso criar testes completos para a seguinte página/widget Flutter:

**Arquivo:** [caminho completo do arquivo, ex: lib/features/home/home_page.dart]

Por favor:
1. Analise o arquivo e identifique automaticamente:
   - BLoCs/Cubits utilizados
   - Widgets filhos principais
   - Estados possíveis
   - Dependências importantes

2. Gere testes completos seguindo estes requisitos:

**Estrutura dos testes:**
- Criar arquivo de teste em `test/` seguindo a mesma estrutura de diretórios
- Usar `MaterialApp` diretamente, SEM wrapper `EasyLocalization` (para evitar erros de inicialização)
- Incluir apenas `DefaultMaterialLocalizations.delegate` e `DefaultWidgetsLocalizations.delegate`

**Cobertura necessária:**
- Testar todos os estados possíveis (loading, error, loaded, empty, etc.)
- Verificar renderização de widgets principais
- Testar interações do usuário (taps, scrolls, inputs)
- Validar callbacks e eventos do BLoC
- Testar edge cases (listas vazias, dados nulos, etc.)

**Padrões a seguir:**
- Seguir as diretrizes do arquivo `.cursorrules`
- Usar `mocktail` para mocks
- Criar mocks para BLoCs/Cubits e outros serviços
- Usar `registerFallbackValue` para eventos/estados customizados
- Cada teste deve ser independente e isolado
- Usar `pumpWidget` e `pumpAndSettle` apropriadamente

**Evitar:**
- Não usar `EasyLocalization` wrapper nos testes
- Não assumir que widgets existem sem verificar a implementação
- Não criar testes para widgets que não estão implementados

**Convenções de Nomenclatura:**
- Usar verbos no presente nas descrições: "renderiza", "exibe", "valida", "dispara"
- Ser específico sobre o cenário testado (ex: "renderiza botão de erro quando falha")
- NÃO usar "testa se..." ou "verifica que..."

**Exemplo de estrutura esperada:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends Mock implements MyBloc {}
class FakeEvent extends Fake implements MyEvent {}

void main() {
  late _MockBloc mockBloc;

  setUpAll(() {
    registerFallbackValue(FakeEvent());
  });

  setUp(() {
    mockBloc = _MockBloc();
  });

  group('MyWidget', () {
    testWidgets('renderiza loading state', (tester) async {
      when(() => mockBloc.state).thenReturn(MyLoading());
      when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: MyWidget(bloc: mockBloc),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
````

Gere os testes completos com boa cobertura de todos os cenários possíveis.

```

---

## Exemplo de Uso Preenchido

```

Preciso criar testes completos para a seguinte página/widget Flutter:

**Arquivo:** lib/features/home/home_page.dart

Por favor:

1. Analise o arquivo e identifique automaticamente:

   - BLoCs/Cubits utilizados
   - Widgets filhos principais
   - Estados possíveis
   - Dependências importantes

2. Gere testes completos seguindo estes requisitos:
   [... resto do template ...]

````

## Boas Práticas Adicionais

### Informações Importantes para Incluir

- **Navegação:** Se o widget navega para outras telas, mencione as rotas
- **Formulários:** Se há campos de input, liste os validadores necessários
- **Animações:** Indique se há animações ou transições importantes
- **Permissões:** Mencione se o widget requer permissões especiais
- **APIs/Serviços:** Liste chamadas de API ou serviços externos

### Checklist Pré-Geração

Antes de solicitar a geração dos testes, certifique-se de:

- [ ] A implementação do widget está completa
- [ ] O BLoC/Cubit está implementado e testado
- [ ] Todos os widgets filhos estão implementados
- [ ] As dependências estão corretamente configuradas no `pubspec.yaml`
- [ ] Você identificou todos os estados possíveis do widget

### Após Geração dos Testes

1. **Execute os testes:** `flutter test test/caminho/do/arquivo_test.dart`
2. **Verifique a cobertura:** Certifique-se de que todos os cenários foram cobertos
3. **Ajuste conforme necessário:** Adicione testes para casos específicos que possam ter sido esquecidos
4. **Documente casos especiais:** Se houver comportamentos não óbvios, adicione comentários nos testes

---

## Padrões de Nomenclatura

### Arquivos de Teste

- Seguir a mesma estrutura de diretórios do código fonte
- Adicionar sufixo `_test.dart`
- Exemplo: `lib/features/home/home_page.dart` → `test/features/home/home_page_test.dart`

### Grupos de Teste

- Usar o nome do widget/classe como nome do grupo principal
- Agrupar testes relacionados em subgrupos quando apropriado
- Exemplo:
  ```dart
  group('HomePage', () {
    group('Loading State', () { ... });
    group('Error State', () { ... });
    group('Loaded State', () { ... });
  });
````

```

### Descrições de Teste

- Usar verbos no presente: "renderiza", "exibe", "valida"
- Ser específico sobre o que está sendo testado
- Exemplos:
  - ✅ "renderiza CircularProgressIndicator em estado loading"
  - ✅ "exibe mensagem de erro quando falha ao carregar dados"
  - ❌ "testa loading"
  - ❌ "verifica erro"

---

## Troubleshooting

### Problemas Comuns

#### 1. `LateInitializationError` com `EasyLocalization`

**Solução:** Não use `EasyLocalization` wrapper nos testes. Use apenas `MaterialApp` com delegates padrão.

#### 2. Widgets não encontrados

**Solução:** Verifique se o widget realmente é renderizado no estado testado. Use `tester.pumpAndSettle()` após `pumpWidget()`.

#### 3. Múltiplos widgets encontrados quando esperava apenas um

**Solução:** Use finders mais específicos ou verifique se o widget não está sendo renderizado em múltiplos lugares (ex: header + card).

#### 4. Testes falhando por timeout

**Solução:** Aumente o timeout ou verifique se há animações infinitas. Use `tester.pumpAndSettle()` com cuidado.

---

## Recursos Adicionais

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Flutter BLoC Testing](https://bloclibrary.dev/#/testing)
- [Widget Testing Best Practices](https://docs.flutter.dev/cookbook/testing/widget/introduction)
```
