import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/features/signup/bloc/simple_signup_bloc.dart';
import 'package:terafy/features/signup/bloc/simple_signup_bloc_models.dart';
import 'package:terafy/features/signup/widgets/simple_signup_form.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';

class SimpleSignupPage extends StatelessWidget {
  const SimpleSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SimpleSignupBloc(
        registerUserUseCase: DependencyContainer().registerUserUseCase,
        secureStorageService: DependencyContainer().secureStorageService,
      ),
      child: const _SimpleSignupPageContent(),
    );
  }
}

class _SimpleSignupPageContent extends StatelessWidget {
  const _SimpleSignupPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SimpleSignupBloc, SimpleSignupState>(
      listener: (context, state) async {
        if (state is SimpleSignupSuccess) {
          // Após registro bem-sucedido, faz login automático e verifica se precisa completar perfil
          try {
            final secureStorage = DependencyContainer().secureStorageService;
            final token = await secureStorage.getToken();

            if (token != null && context.mounted) {
              // Busca dados do usuário para verificar se tem accountId
              final getCurrentUserUseCase = DependencyContainer().getCurrentUserUseCase;
              final authResult = await getCurrentUserUseCase();

              if (authResult.client != null && context.mounted) {
                final accountId = authResult.client!.accountId;

                if (accountId == null) {
                  // Cadastro incompleto - redireciona para completar perfil
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRouter.completeProfileRoute, arguments: {'email': state.email});
                } else {
                  // Cadastro completo - vai para home
                  Navigator.of(context).pushReplacementNamed(AppRouter.homeRoute);
                }
              }
            }
          } catch (e) {
            // Em caso de erro, apenas vai para completar perfil como fallback
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushReplacementNamed(AppRouter.completeProfileRoute, arguments: {'email': state.email});
            }
          }
        } else if (state is SimpleSignupFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: AppColors.error));
        }
      },
      builder: (context, state) {
        final isLoading = state is SimpleSignupLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.offBlack),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Criar Conta', style: const TextStyle(color: AppColors.offBlack)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SimpleSignupForm(
              onSignup: ({required String email, required String password}) {
                if (!isLoading) {
                  context.read<SimpleSignupBloc>().add(SimpleSignupSubmitted(email: email, password: password));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
