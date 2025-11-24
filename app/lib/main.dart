import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/common/app_theme.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/navigation/app_navigator.dart';
import 'package:flutter/foundation.dart';
import 'package:common/common.dart';

/// Determina se deve usar modo debug baseado na mesma lógica do _baseUrl
/// Usa a mesma lógica: se estiver usando localhost/10.0.2.2 = debug, se usar IP externo = produção
bool _shouldUseDebugMode() {
  // Permite forçar via variável de ambiente
  final forceRelease = const bool.fromEnvironment('FORCE_RELEASE', defaultValue: false);
  if (forceRelease) return false;

  // Usa a mesma lógica do _baseUrl em dependency_container.dart
  if (kIsWeb) {
    // Web em desenvolvimento usa localhost - mantém debug
    return kDebugMode;
  }

  if (kDebugMode) {
    // Se está em kDebugMode, está em desenvolvimento
    // Usa localhost ou 10.0.2.2 - mantém debug ligado
    return true;
  }

  // Se não está em kDebugMode, está em release mode
  // Usa IP de produção (35.224.10.2) - desliga debug
  return false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura o logger ANTES de tudo
  // Usa a mesma lógica do _baseUrl para determinar se está em produção
  // Se estiver usando IP de produção (não localhost), desliga debug
  final bool isDebugMode = _shouldUseDebugMode();
  AppLogger.config(isDebugMode: isDebugMode);

  await EasyLocalization.ensureInitialized();

  DependencyContainer().setup();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('pt', 'BR')],
      path: 'assets/translations',
      fallbackLocale: const Locale('pt', 'BR'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configura o interceptor de autenticação com callback para redirecionar quando token expira
    DependencyContainer().setupAuthInterceptor(
      onTokenExpired: () {
        // Quando o token expira, navega para login
        // Usamos um Navigator global se disponível
        // Por enquanto, o interceptor apenas limpa as credenciais
        // O redirecionamento será tratado quando a próxima requisição falhar
      },
    );

    return MaterialApp(
      title: 'Terafy',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splashRoute,
      onGenerateRoute: AppRouter.generateRoute,
      navigatorKey: navigatorKey, // Adiciona global navigator key
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).colorScheme.inversePrimary, title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text('0', style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, tooltip: 'Increment', child: const Icon(Icons.add)),
    );
  }
}
