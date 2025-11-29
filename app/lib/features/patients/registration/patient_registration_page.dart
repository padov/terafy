import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_bloc.dart';
import 'package:terafy/features/patients/registration/bloc/patient_registration_models.dart';
import 'package:terafy/features/patients/registration/widgets/step1_identification.dart';
import 'package:terafy/features/patients/registration/widgets/step2_contact.dart';
import 'package:terafy/features/patients/registration/widgets/step3_professional_social.dart';
import 'package:terafy/features/patients/registration/widgets/step4_health.dart';
import 'package:terafy/features/patients/registration/widgets/step6_administrative.dart';

class PatientRegistrationPage extends StatelessWidget {
  final Patient? patientToEdit;

  const PatientRegistrationPage({super.key, this.patientToEdit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatientRegistrationBloc(patientToEdit: patientToEdit),
      child: _PatientRegistrationContent(isEditMode: patientToEdit != null),
    );
  }
}

class _PatientRegistrationContent extends StatelessWidget {
  final bool isEditMode;

  const _PatientRegistrationContent({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PatientRegistrationBloc, PatientRegistrationState>(
      listener: (context, state) {
        if (state is PatientRegistrationSuccess) {
          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Paciente atualizado com sucesso!'
                    : 'Paciente cadastrado com sucesso!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Voltar para a tela anterior
          Navigator.of(context).pop(true);
        } else if (state is PatientRegistrationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<PatientRegistrationBloc>();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              isEditMode ? 'Editar Paciente' : 'Cadastro Completo de Paciente',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.offBlack,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value:
                    (state.currentStep + 1) /
                    PatientRegistrationBloc.totalSteps,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Stepper Header
              _buildStepperHeader(context, state.currentStep),

              // Content
              Expanded(child: _buildStepContent(context, state)),

              // Navigation Buttons
              _buildNavigationButtons(context, bloc, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepperHeader(BuildContext context, int currentStep) {
    final steps = [
      {'icon': Icons.person, 'label': 'Identificação'},
      {'icon': Icons.contact_phone, 'label': 'Contato'},
      {'icon': Icons.work, 'label': 'Profissional'},
      {'icon': Icons.medical_services, 'label': 'Saúde'},
      {'icon': Icons.settings, 'label': 'Administrativo'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.offBlack.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            final step = steps[index];

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : isCompleted
                            ? Colors.green
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step['icon'] as IconData,
                        color: isActive || isCompleted
                            ? Colors.white
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        step['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isActive
                              ? AppColors.primary
                              : isCompleted
                              ? Colors.green
                              : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 30,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 30),
                    color: index < currentStep
                        ? Colors.green
                        : Colors.grey[300],
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    PatientRegistrationState state,
  ) {
    final bloc = context.read<PatientRegistrationBloc>();

    switch (state.currentStep) {
      case 0:
        return Step1Identification(
          initialData: state.data.identification,
          onDataChanged: (data) {
            bloc.add(UpdateIdentificationData(data));
          },
        );
      case 1:
        return Step2Contact(
          initialData: state.data.contact,
          dateOfBirth: state.data.identification?.dateOfBirth,
          onDataChanged: (data) {
            bloc.add(UpdateContactData(data));
          },
        );
      case 2:
        return Step3ProfessionalSocial(
          initialData: state.data.professionalSocial,
          onDataChanged: (data) {
            bloc.add(UpdateProfessionalSocialData(data));
          },
        );
      case 3:
        return Step4Health(
          initialData: state.data.health,
          onDataChanged: (data) {
            bloc.add(UpdateHealthData(data));
          },
        );
      case 4:
        return Step6Administrative(
          initialData: state.data.administrative,
          onDataChanged: (data) {
            bloc.add(UpdateAdministrativeData(data));
          },
        );
      default:
        return const Center(child: Text('Step não encontrado'));
    }
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    PatientRegistrationBloc bloc,
    PatientRegistrationState state,
  ) {
    final isFirstStep = state.currentStep == 0;
    final isLastStep =
        state.currentStep == PatientRegistrationBloc.totalSteps - 1;
    final canProceed = bloc.canProceedToNextStep();
    final isLoading = state is PatientRegistrationLoading;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.offBlack.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Botão Voltar
            if (!isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => bloc.add(PreviousStepPressed()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            if (!isFirstStep) const SizedBox(width: 12),

            // Botão Próximo/Finalizar
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading || !canProceed
                    ? null
                    : () {
                        if (isLastStep) {
                          bloc.add(SavePatientPressed());
                        } else {
                          bloc.add(NextStepPressed());
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isLastStep
                            ? (isEditMode ? 'Salvar Alterações' : 'Finalizar Cadastro')
                            : 'Próximo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
