import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/common/app_images.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/core/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SecureStorageService _secureStorage = DependencyContainer().secureStorageService;
  final AuthService _authService = DependencyContainer().authService;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Carrega a versão em paralelo ao delay
    final versionFuture = PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = 'Versão ${info.version}';
        });
      }
    });

    // Aguarda um mínimo de 2 segundos para mostrar o splash
    await Future.wait([Future.delayed(const Duration(seconds: 2)), versionFuture]);

    if (!mounted) return;

    final token = await _secureStorage.getToken();
    final userIdentifier = await _secureStorage.getUserIdentifier();
    final canCheckBiometrics = await _authService.canCheckBiometrics();

    // Se não há token ou não há biometria configurada, vai para login
    if (token == null || userIdentifier == null || !canCheckBiometrics) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
      }
      return;
    }

    // Se há token e biometria configurada, tenta login automático
    // Navega para login, que automaticamente tentará biometria
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Image.asset(AppImages.logoApp, height: 200)),
            if (_version.isNotEmpty)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _version,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
