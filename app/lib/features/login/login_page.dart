import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/login/bloc/login_bloc.dart';
import 'package:terafy/features/login/bloc/login_bloc_models.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/common/app_images.dart';
import 'package:terafy/routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometryEnabled = false;
  bool _canCheckBiometrics = false;

  final AuthService _authService = DependencyContainer().authService;
  final SecureStorageService _secureStorage = DependencyContainer().secureStorageService;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    // Verifica apenas se o dispositivo suporta biometria e se já está habilitada
    final canCheck = await _authService.canCheckBiometrics();
    final userIdentifier = await _secureStorage.getUserIdentifier();
    final isBiometryEnabled = userIdentifier != null;

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _biometryEnabled = isBiometryEnabled;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(sessionManager: DependencyContainer().sessionManager),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) async {
          if (state is LoginSuccess) {
            setState(() => _isLoading = false);
            if (context.mounted) {
              // Verifica se precisa completar o perfil
              if (state.requiresProfileCompletion) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRouter.completeProfileRoute, arguments: {'email': state.client.email});
              } else {
                Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
              }
            }
          } else if (state is LoginFailure) {
            setState(() => _isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
            }
          } else if (state is LoginLoading) {
            setState(() => _isLoading = true);
          } else if (state is LoginInitial) {
            setState(() => _isLoading = false);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.white,
            body: Column(
              children: [
                // Header com logo e background roxo
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
                      center: Alignment.center,
                      radius: 1.5,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Column(
                        children: [
                          // Logo
                          Container(
                            height: MediaQuery.of(context).size.height * 0.25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.offBlack.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(AppImages.logoApp, fit: BoxFit.fitHeight),
                          ),

                          // Subtítulo
                          Text(
                            'login.subtitle'.tr(),
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.9)),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Conteúdo scrollável
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Formulário
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label Email
                              Text(
                                'login.email_label'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.offBlack,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Campo Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'login.email_placeholder'.tr(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email é obrigatório';
                                  }
                                  // Valida tamanho máximo do email (RFC 5321: máximo 320 caracteres, mas usamos 254 como limite prático)
                                  if (value.length > 254) {
                                    return 'Email inválido';
                                  }
                                  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Label Password
                              Text(
                                'login.password_label'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.offBlack,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Campo Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'login.password_placeholder'.tr(),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Senha é obrigatória';
                                  }
                                  if (value.length < 6) {
                                    return 'Senha deve ter no mínimo 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // Forgot Password e Biometria
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Implement forgot password
                                    },
                                    child: Text(
                                      'login.forgot_password'.tr(),
                                      style: TextStyle(
                                        color: AppColors.offBlack,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (_canCheckBiometrics)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.scale(
                                          scale: 0.7,
                                          child: Switch(
                                            value: _biometryEnabled,
                                            onChanged: (value) {
                                              context.read<LoginBloc>().add(
                                                BiometricsPreferenceChanged(enabled: value),
                                              );
                                              if (mounted) {
                                                setState(() {
                                                  _biometryEnabled = value;
                                                });
                                              }
                                            },
                                            activeColor: AppColors.primary,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.fingerprint,
                                          color: _biometryEnabled ? AppColors.primary : Colors.grey[400],
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Botão Sign In
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () => _handleSignIn(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          'login.sign_in_button'.tr(),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider "Or sign in with"
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.lightBorderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'login.or_sign_in_with'.tr(),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.lightBorderColor)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Botões de Login Social
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                              onTap: () {
                                // TODO: Implement Apple Sign In
                              },
                              icon: AppImages.appleIcon,
                            ),
                            const SizedBox(width: 16),
                            _socialButton(
                              onTap: () {
                                context.read<LoginBloc>().add(LoginWithGooglePressed());
                              },
                              icon: AppImages.googleIcon,
                            ),
                            const SizedBox(width: 16),
                            _socialButton(
                              onTap: () {
                                // TODO: Implement Facebook Sign In
                              },
                              icon: AppImages.facebookIcon,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('login.no_account'.tr(), style: TextStyle(color: AppColors.offBlack, fontSize: 14)),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(AppRouter.signupRoute);
                              },
                              child: Text(
                                'login.sign_up'.tr(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _socialButton({required VoidCallback onTap, required String icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorderColor),
        ),
        child: Center(child: SvgPicture.asset(icon, width: 28, height: 28)),
      ),
    );
  }

  void _handleSignIn(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
        LoginButtonPressed(
          email: _emailController.text,
          password: _passwordController.text,
          isBiometricsEnabled: _biometryEnabled,
        ),
      );
    }
  }
}
