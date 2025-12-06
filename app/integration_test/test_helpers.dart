import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/common/app_theme.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/core/navigation/app_navigator.dart';
import 'package:flutter/foundation.dart';
import 'package:common/common.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'test_auth_service.dart';

/// Helper class for integration tests
class IntegrationTestHelpers {
  /// Creates and pumps the app widget for testing
  static Future<void> pumpApp(WidgetTester tester, {String initialRoute = AppRouter.loginRoute}) async {
    // IMPORTANTE: Limpa o storage ANTES de inicializar o app
    // Isso evita que tokens salvos causem login automático
    await clearAppData();

    // Initialize EasyLocalization
    await EasyLocalization.ensureInitialized();

    // Setup dependencies (só inicializa se ainda não foi inicializado)
    final container = DependencyContainer();
    try {
      // Tenta acessar para verificar se já está inicializado
      final _ = container.secureStorageService;
    } catch (e) {
      // Se não estiver inicializado, inicializa agora
      container.setup();
    }

    // SEMPRE substitui o AuthService pelo TestAuthService nos testes de integração
    // Isso garante que a biometria seja simulada sem solicitar interação real
    final testAuthService = TestAuthService();
    testAuthService.setBiometricsAvailable(true);
    testAuthService.setAuthenticateResult(true);
    container.setAuthServiceForTests(testAuthService);

    // Configura o AuthInterceptor (necessário para adicionar token nas requisições)
    // Isso é feito no main.dart, mas precisa ser feito também nos testes
    container.setupAuthInterceptor();

    // Configure logger
    AppLogger.config(isDebugMode: kDebugMode);

    // Create the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt', 'BR')],
        path: 'assets/translations',
        fallbackLocale: const Locale('pt', 'BR'),
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Terafy',
            theme: AppTheme.lightTheme,
            initialRoute: initialRoute,
            onGenerateRoute: AppRouter.generateRoute,
            navigatorKey: navigatorKey,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );

    // Wait for the app to settle
    // IMPORTANTE: Para rotas que não são login, NÃO usa pumpAndSettle
    // porque isso permite que Future.microtask e outras operações assíncronas sejam executadas,
    // o que pode causar redirecionamentos indesejados (ex: LoginBloc.CheckBiometricLogin)
    if (initialRoute == AppRouter.loginRoute) {
      // Para login, pode usar pumpAndSettle pois o LoginBloc tem lógica de inicialização
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      // Para outras rotas (como signup), usa apenas um pump único e mínimo
      // Isso renderiza o widget mas NÃO permite que Future.microtask seja executado
      // O Future.microtask só será executado quando o próximo pump() for chamado
      await tester.pump(); // Apenas um pump para renderizar o widget inicial
      // NÃO faz mais pumps aqui - deixa para o teste decidir quando fazer pump
    }
  }

  /// Waits for a specific duration
  static Future<void> wait(WidgetTester tester, Duration duration) async {
    await tester.pump(duration);
  }

  /// Waits for animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Enters text into a text field (simula comportamento humano)
  static Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
    // 1. Foca no campo (como um humano faria - clica no campo primeiro)
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 150));

    // 2. Limpa o campo se tiver texto (simula selecionar tudo e apagar)
    // Primeiro tenta limpar selecionando tudo
    final field = tester.widget<TextFormField>(finder);
    if (field.controller != null && field.controller!.text.isNotEmpty) {
      // Move cursor para o início
      field.controller!.selection = TextSelection(baseOffset: 0, extentOffset: field.controller!.text.length);
      await tester.pump(const Duration(milliseconds: 50));

      // Apaga o texto
      await tester.enterText(finder, '');
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 3. Digita o texto (como um humano faria - de uma vez)
    await tester.enterText(finder, text);

    // 4. Aguarda o texto ser processado e renderizado
    // Usa pumpAndSettle com timeout curto para processar animações
    // mas não espera muito tempo (como um humano não espera)
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Taps a widget
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Scrolls until a widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100,
  }) async {
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    await tester.pumpAndSettle();
  }

  /// Verifies that a widget exists
  static void expectToFind(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that a widget does not exist
  static void expectNotToFind(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies that multiple widgets exist
  static void expectToFindMultiple(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Clears app data (logout and clear storage)
  /// Limpa o storage ANTES de inicializar o DependencyContainer
  /// para evitar que tokens salvos causem login automático
  static Future<void> clearAppData() async {
    // Limpa o storage diretamente usando FlutterSecureStorage
    // Isso garante que os dados sejam limpos mesmo antes do DependencyContainer estar inicializado
    const storage = FlutterSecureStorage();

    try {
      // Limpa todas as chaves de autenticação
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'user_identifier');
    } catch (e) {
      // Se falhar, tenta limpar via DependencyContainer se estiver inicializado
      try {
        final container = DependencyContainer();
        final secureStorage = container.secureStorageService;
        await secureStorage.clearAll();
      } catch (_) {
        // Se ambos falharem, apenas loga o erro mas continua
        // (pode ser que o storage não exista ainda, o que é OK)
      }
    }
  }

  /// Simulates app restart by disposing and recreating dependencies
  /// IMPORTANTE: NÃO limpa o storage, mantém tokens salvos para testar persistência
  static Future<void> restartApp(WidgetTester tester) async {
    // Clear the current widget tree
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();

    // Reinitialize the app (sem limpar storage - mantém tokens)
    // Não chama clearAppData() para manter tokens salvos
    await EasyLocalization.ensureInitialized();

    final container = DependencyContainer();
    try {
      // Verifica se já está inicializado
      final _ = container.secureStorageService;
    } catch (e) {
      // Se não estiver inicializado, inicializa agora
      container.setup();
    }

    // Garante que o TestAuthService está configurado
    final testAuthService = TestAuthService();
    testAuthService.setBiometricsAvailable(true);
    testAuthService.setAuthenticateResult(true);
    container.setAuthServiceForTests(testAuthService);

    // Configura o AuthInterceptor
    container.setupAuthInterceptor();

    // Configure logger
    AppLogger.config(isDebugMode: kDebugMode);

    // Create the app
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('pt', 'BR')],
        path: 'assets/translations',
        fallbackLocale: const Locale('pt', 'BR'),
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'Terafy',
            theme: AppTheme.lightTheme,
            initialRoute: AppRouter.splashRoute,
            onGenerateRoute: AppRouter.generateRoute,
            navigatorKey: navigatorKey,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
          ),
        ),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();
  }
}

/// Common test data
class TestData {
  static const String validEmail = 'teste@terafy.app.br';
  static const String validPassword = '123456';
  static const String invalidEmail = 'invalid@test.com';
  static const String invalidPassword = 'wrongpassword';
  static const String malformedEmail = 'notanemail';
}
