import 'package:flutter/material.dart';
import 'package:terafy/common/app_images.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo da aplicação
        SvgPicture.asset(AppImages.logoApp, width: 180, height: 180),
        const SizedBox(height: 24),

        // Texto de boas-vindas
        const Text(
          'Bem-vindo!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Entre com sua conta para continuar',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
