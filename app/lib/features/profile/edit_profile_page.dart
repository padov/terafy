import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/features/profile/edit_profile_bloc.dart';
import 'package:terafy/features/profile/edit_profile_bloc_models.dart';
import 'package:terafy/features/signup/widgets/signup_step1_personal.dart';
import 'package:terafy/features/signup/widgets/signup_step2_professional.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditProfileBloc(
        getCurrentTherapistUseCase: DependencyContainer().getCurrentTherapistUseCase,
        updateTherapistUseCase: DependencyContainer().updateTherapistUseCase,
      ),
      child: const _EditProfilePageContent(),
    );
  }
}

class _EditProfilePageContent extends StatefulWidget {
  const _EditProfilePageContent();

  @override
  State<_EditProfilePageContent> createState() =>
      _EditProfilePageContentState();
}

class _EditProfilePageContentState extends State<_EditProfilePageContent> {
  final _personalFormKey = GlobalKey<FormState>();
  final _professionalFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileBloc, EditProfileState>(
      listener: (context, state) {
        if (state is EditProfileSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is EditProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is EditProfileLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Editar Perfil',
                style: TextStyle(color: AppColors.offBlack),
              ),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is EditProfileFailure && state.data.name == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Editar Perfil',
                style: TextStyle(color: AppColors.offBlack),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    state.error,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<EditProfileBloc>().add(const LoadProfileData());
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.offBlack,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Editar Perfil',
              style: TextStyle(color: AppColors.offBlack),
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
        children: List.generate(2, (index) {
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
                if (index < 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, EditProfileState state) {
    switch (state.currentStep) {
      case 0:
        return SignupStep1Personal(
          formKey: _personalFormKey,
          initialName: state.data.name,
          initialNickname: state.data.nickname,
          initialLegalDocument: state.data.legalDocument,
          initialEmail: state.data.email,
          initialPhone: state.data.phone,
          initialPassword: '',
          initialBirthday: state.data.birthday,
          showPasswordFields: false, // Não mostra campos de senha na edição
          readOnlyEmail: true, // Email não pode ser editado
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
                context.read<EditProfileBloc>().add(
                  UpdatePersonalData(
                    name: name,
                    nickname: nickname,
                    legalDocument: legalDocument,
                    email: email,
                    phone: phone,
                    birthday: birthday,
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
                context.read<EditProfileBloc>().add(
                  UpdateProfessionalData(
                    specialties: specialties,
                    professionalRegistrations: professionalRegistrations,
                    presentation: presentation,
                    address: address,
                  ),
                );
              },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomButton(BuildContext context, EditProfileState state) {
    final isLastStep = state.currentStep == 1;
    final isLoading = state is EditProfileSaving;

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
                      context.read<EditProfileBloc>().add(
                        const NextStepPressed(),
                      );
                    } else if (state.currentStep == 1) {
                      // Último step - valida e salva
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

                      // Salva o perfil
                      context.read<EditProfileBloc>().add(
                        const SubmitEditProfile(),
                      );
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
                    isLastStep ? 'Salvar' : 'Próximo',
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
