import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/features/splash/splash_page.dart';
import 'package:terafy/routes/app_routes.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockSecureStorageService mockSecureStorage;
  late MockAuthService mockAuthService;

  setUp(() {
    mockSecureStorage = MockSecureStorageService();
    mockAuthService = MockAuthService();

    // Mock DependencyContainer
    final container = DependencyContainer();
    container.secureStorageService = mockSecureStorage;
    container.authService = mockAuthService;
  });

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Terafy',
      packageName: 'com.terafy.app',
      version: '0.3.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('SplashPage displays version number', (WidgetTester tester) async {
    // Arrange
    when(() => mockSecureStorage.getToken()).thenAnswer((_) async => null);
    when(() => mockSecureStorage.getUserIdentifier()).thenAnswer((_) async => null);
    when(() => mockAuthService.canCheckBiometrics()).thenAnswer((_) async => false);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == AppRouter.loginRoute) {
            return MaterialPageRoute(builder: (_) => Container());
          }
          return AppRouter.generateRoute(settings);
        },
        home: const SplashPage(),
      ),
    ); // Assert
    // Advance time to satisfy the 2-second delay
    await tester.pump(const Duration(seconds: 2));
    // Pump one more frame to allow the FutureBuilder/setState to update
    await tester.pump();

    expect(find.text('Versão 0.3.0'), findsOneWidget);
  });
}
