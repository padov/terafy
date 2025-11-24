import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terafy/features/signup/bloc/signup_bloc.dart';
import 'package:terafy/features/signup/bloc/signup_bloc_models.dart';
import 'package:terafy/features/signup/widgets/signup_step1_personal.dart';
import 'package:terafy/features/signup/widgets/signup_step2_professional.dart';
import 'package:terafy/features/signup/widgets/signup_step3_plan.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/routes/app_routes.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignupBloc(
        registerUserUseCase: DependencyContainer().registerUserUseCase,
        createTherapistUseCase: DependencyContainer().createTherapistUseCase,
      ),
      child: const _SignupPageContent(),
    );
  }
}

class _SignupPageContent extends StatefulWidget {
  const _SignupPageContent();

  @override
  State<_SignupPageContent> createState() => _SignupPageContentState();
}

class _SignupPageContentState extends State<_SignupPageContent> {
  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state is SignupSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('signup.success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pushReplacementNamed(AppRouter.loginRoute);
        } else if (state is SignupFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: state.currentStep > 0
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.offBlack,
                    ),
                    onPressed: () {
                      context.read<SignupBloc>().add(
                        const PreviousStepPressed(),
                      );
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.close, color: AppColors.offBlack),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: Text(
              'signup.title'.tr(),
              style: const TextStyle(color: AppColors.offBlack),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(context, state.currentStep),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildStepContent(context, state),
                ),
              ),

              // Bottom Action Button
              _buildBottomButton(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, SignupState state) {
    switch (state.currentStep) {
      case 0:
        return SignupStep1Personal(
          formKey: _personalFormKey,
          initialName: state.data.name,
          initialNickname: state.data.nickname,
          initialLegalDocument: state.data.legalDocument,
          initialEmail: state.data.email,
          initialPhone: state.data.phone,
          initialPassword: state.data.password,
          initialBirthday: state.data.birthday,
          onDataChanged:
              ({
                required String name,
                required String nickname,
                required String legalDocument,
                required String email,
                required String phone,
                String? password,
                DateTime? birthday,
              }) {
                context.read<SignupBloc>().add(
                  UpdatePersonalData(
                    name: name,
                    nickname: nickname,
                    legalDocument: legalDocument,
                    email: email,
                    phone: phone,
                    birthday: birthday,
                    password: password ?? '',
                  ),
                );
              },
        );
      case 1:
        return SignupStep2Professional(
          formKey: _professionalFormKey,
          initialSpecialties: state.data.specialties,
          initialProfessionalRegistrations:
              state.data.professionalRegistrations,
          initialPresentation: state.data.presentation,
          initialAddress: state.data.address,
          onDataChanged:
              ({
                required List<String> specialties,
                required List<String> professionalRegistrations,
                required String presentation,
                required String address,
              }) {
                context.read<SignupBloc>().add(
                  UpdateProfessionalData(
                    specialties: specialties,
                    professionalRegistrations: professionalRegistrations,
                    presentation: presentation,
                    address: address,
                  ),
                );
              },
        );
      case 2:
        return SignupStep3Plan(
          initialPlanId: state.data.planId,
          onPlanSelected: (planId) {
            context.read<SignupBloc>().add(SelectPlan(planId));
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButton(BuildContext context, SignupState state) {
    final isLastStep = state.currentStep == 2;
    final isLoading = state is SignupLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.offBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    final messenger = ScaffoldMessenger.of(context);

                    if (state.currentStep == 0) {
                      final isValid =
                          _personalFormKey.currentState?.validate() ?? false;
                      if (!isValid) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Verifique os dados pessoais informados.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      context.read<SignupBloc>().add(const NextStepPressed());
                    } else if (state.currentStep == 1) {
                      final isValid =
                          _professionalFormKey.currentState?.validate() ?? true;

                      if (!isValid) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Verifique os dados profissionais informados.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if ((state.data.specialties ?? []).isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Adicione pelo menos uma especialidade.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      if ((state.data.professionalRegistrations ?? [])
                          .isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Informe pelo menos um registro profissional.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      context.read<SignupBloc>().add(const NextStepPressed());
                    } else {
                      if (state.data.planId == null) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Selecione um plano para continuar.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      context.read<SignupBloc>().add(const SubmitSignup());
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    isLastStep ? 'signup.finish'.tr() : 'signup.next'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
