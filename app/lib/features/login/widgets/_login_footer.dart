import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});
  final textStyle = const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.54,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primaryText,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: textStyle,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Text(
            'Ainda não tem uma conta? Crie uma agora',
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
