import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:terafy/features/login/bloc/login_bloc_models.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/core/services/auth_service.dart';
import 'package:terafy/core/services/secure_storage_service.dart';
import 'package:terafy/features/login/bloc/login_bloc.dart';
import 'package:terafy/common/app_images.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/routes/app_routes.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _biometryEnabled = false;
  bool _isLoading = false;
  bool _canCheckBiometrics = false;
  String? _savedUserIdentifier;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;

  // Injetando serviços
  final AuthService _authService = DependencyContainer().authService;
  final SecureStorageService _storageService =
      DependencyContainer().secureStorageService;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _authService.canCheckBiometrics();
    final savedUser = await _storageService.getUserIdentifier();

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _savedUserIdentifier = savedUser;
        // Se já houver um usuário salvo, marcamos o switch como ativo
        if (savedUser != null) {
          _biometryEnabled = true;
          _userController.text = savedUser;
          // Se entramos na tela já com biometria ativa, aciona o prompt
          context.read<LoginBloc>().add(LoginWithBiometrics());
        }
      });
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  TextStyle textStyle(BuildContext context) {
    return TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.54,
    );
  }

  Future<void> _login(BuildContext blocContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    log(
      'Botão de login pressionado. Enviando evento para o BLoC.',
      name: 'LoginForm',
    );
    // Dispara o evento para o BLoC, incluindo o estado atual do Switch
    blocContext.read<LoginBloc>().add(
      LoginButtonPressed(
        email: _userController.text,
        password: _passwordController.text,
        isBiometricsEnabled: _biometryEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) async {
        // Tornando o listener assíncrono
        if (state is LoginSuccess) {
          Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
        } else if (state is LoginSuccessAskBiometrics) {
          // Pede a confirmação biométrica
          final isAuthenticated = await _authService.authenticate();
          if (isAuthenticated && context.mounted) {
            // Se confirmado, navega para a home
            Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
          } else if (context.mounted) {
            // Se o usuário cancelar, ele permanece na tela de login, mas logado.
            // Poderíamos navegar para a home de qualquer maneira ou mostrar uma mensagem.
            // Por enquanto, vamos navegar para a home para uma melhor UX.
            Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
          }
        } else if (state is LoginFailure) {
          // Garante que o estado de loading seja removido
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is LoginLoading) {
          if (mounted) {
            setState(() {
              _isLoading = true;
            });
          }
        } else if (state is LoginInitial) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      builder: (context, state) {
        // A UI principal não precisa ser reconstruída pelo builder,
        // pois o setState já cuida do _isLoading.
        // O builder ainda é necessário para a estrutura do BlocConsumer.
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _userTextField(),
              const SizedBox(height: 7),
              _passwordTextField(),
              const SizedBox(height: 8),
              _recoverPasswordAndBiometricButton(context),
              const SizedBox(height: 32),
              _loginButton(context), // Passando o context do builder
              const SizedBox(height: 12),
              _loginSocialButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _userTextField() {
    return TextFormField(
      controller: _userController,
      decoration: InputDecoration(
        hintText: 'CPF, telefone ou email',
        hintStyle: textStyle(context),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(9)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      style: textStyle(context),
    );
  }

  Widget _passwordTextField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        hintText: 'Digite sua senha',
        hintStyle: textStyle(context),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(9)),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        // Adiciona o botão de biometria se aplicável
        suffixIcon: _savedUserIdentifier != null && _canCheckBiometrics
            ? IconButton(
                icon: Icon(Icons.fingerprint, color: AppColors.primaryText),
                onPressed: () {
                  context.read<LoginBloc>().add(LoginWithBiometrics());
                },
              )
            : null,
      ),
      style: textStyle(context),
    );
  }

  Widget _recoverPasswordAndBiometricButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              // TODO: Implement forgot password
              // Navigator.of(context).pushNamed(AppRouter.forgotPasswordRoute);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              textStyle: textStyle(
                context,
              ).copyWith(decoration: TextDecoration.underline),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
              minimumSize: Size.zero,
            ),
            child: Text('Recuperar senha', style: textStyle(context)),
          ),
          Row(
            children: [
              if (_canCheckBiometrics) ...[
                Text('Utilizar biometria', style: textStyle(context)),
                SizedBox(
                  height: 20,
                  width: 38,
                  child: Transform.scale(
                    scale: 0.5,
                    child: Switch(
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      activeTrackColor: Colors.white.withOpacity(0.3),
                      activeThumbColor: Colors.white,
                      value: _biometryEnabled,
                      onChanged: (value) {
                        // Apenas atualiza o estado visual. A lógica de salvar
                        // foi movida para o BLoC.
                        setState(() {
                          _biometryEnabled = value;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      thumbIcon: WidgetStateProperty.all(
                        const Icon(Icons.fingerprint),
                      ),
                      trackOutlineColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _login(context),
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.transparent,
        backgroundColor: AppColors.secondary,
        disabledBackgroundColor: AppColors.secondary,
        foregroundColor: AppColors.secondaryText,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: _isLoading
          ? SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                color: AppColors.secondaryText,
                strokeWidth: 2,
              ),
            )
          : Text(
              'Entrar',
              style: textStyle(
                context,
              ).copyWith(fontSize: 18, color: AppColors.secondaryText),
            ),
    );
  }

  Widget _loginSocialButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: SvgPicture.asset(AppImages.googleIcon, width: 20, height: 20),
          onPressed: () {
            context.read<LoginBloc>().add(LoginWithGooglePressed());
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: SvgPicture.asset(AppImages.appleIcon, width: 20, height: 20),
          onPressed: () {
            // TODO: Implement Apple Sign-In
          },
        ),
      ],
    );
  }
}
