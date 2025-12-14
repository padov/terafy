import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/entities/auth_result.dart';
import 'package:terafy/core/domain/entities/client.dart';
import 'package:terafy/core/domain/usecases/auth/register_user_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/create_therapist_usecase.dart';
import 'package:terafy/features/signup/bloc/signup_bloc.dart';
import 'package:terafy/features/signup/bloc/signup_bloc_models.dart';

class _MockRegisterUserUseCase extends Mock implements RegisterUserUseCase {}

class _MockCreateTherapistUseCase extends Mock implements CreateTherapistUseCase {}

void main() {
  group('SignupBloc', () {
    late _MockRegisterUserUseCase registerUserUseCase;
    late _MockCreateTherapistUseCase createTherapistUseCase;
    late SignupBloc bloc;

    setUp(() {
      registerUserUseCase = _MockRegisterUserUseCase();
      createTherapistUseCase = _MockCreateTherapistUseCase();
      bloc = SignupBloc(
        registerUserUseCase: registerUserUseCase,
        createTherapistUseCase: createTherapistUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é SignupInitial', () {
      expect(bloc.state, const SignupInitial());
      expect(bloc.state.currentStep, 0);
    });

    blocTest<SignupBloc, SignupState>(
      'emite SignupInProgress quando NextStepPressed é adicionado',
      build: () => bloc,
      act: (bloc) => bloc.add(const NextStepPressed()),
      expect: () => [
        const SignupInProgress(currentStep: 1, data: SignupData()),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'não avança além do último step',
      build: () => bloc,
      seed: () => const SignupInProgress(currentStep: 2, data: SignupData()),
      act: (bloc) => bloc.add(const NextStepPressed()),
      expect: () => [],
    );

    blocTest<SignupBloc, SignupState>(
      'emite SignupInProgress quando PreviousStepPressed é adicionado',
      build: () => bloc,
      seed: () => const SignupInProgress(currentStep: 1, data: SignupData()),
      act: (bloc) => bloc.add(const PreviousStepPressed()),
      expect: () => [
        const SignupInProgress(currentStep: 0, data: SignupData()),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'não retrocede além do primeiro step',
      build: () => bloc,
      act: (bloc) => bloc.add(const PreviousStepPressed()),
      expect: () => [],
    );

    blocTest<SignupBloc, SignupState>(
      'atualiza dados pessoais quando UpdatePersonalData é adicionado',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const UpdatePersonalData(
          name: 'João Silva',
          nickname: 'João',
          legalDocument: '12345678900',
          email: 'joao@test.com',
          phone: '11999999999',
          password: 'senha123',
        ),
      ),
      expect: () => [
        const SignupInProgress(
          currentStep: 0,
          data: SignupData(
            name: 'João Silva',
            nickname: 'João',
            legalDocument: '12345678900',
            email: 'joao@test.com',
            phone: '11999999999',
            password: 'senha123',
          ),
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'atualiza dados profissionais quando UpdateProfessionalData é adicionado',
      build: () => bloc,
      act: (bloc) => bloc.add(
        const UpdateProfessionalData(
          specialties: ['Psicologia'],
          professionalRegistrations: ['CRP 12345'],
          presentation: 'Terapeuta experiente',
          address: 'Rua Teste, 123',
        ),
      ),
      expect: () => [
        const SignupInProgress(
          currentStep: 0,
          data: SignupData(
            specialties: ['Psicologia'],
            professionalRegistrations: ['CRP 12345'],
            presentation: 'Terapeuta experiente',
            address: 'Rua Teste, 123',
          ),
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'seleciona plano quando SelectPlan é adicionado',
      build: () => bloc,
      act: (bloc) => bloc.add(const SelectPlan(1)),
      expect: () => [
        const SignupInProgress(
          currentStep: 0,
          data: SignupData(planId: 1),
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'emite SignupFailure quando SubmitSignup com dados incompletos',
      build: () => bloc,
      act: (bloc) => bloc.add(const SubmitSignup()),
      expect: () => [
        const SignupFailure(
          currentStep: 0,
          data: SignupData(),
          error: 'Preencha todos os dados obrigatórios antes de continuar.',
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'emite SignupLoading e SignupSuccess quando SubmitSignup com dados válidos',
      build: () {
        when(() => registerUserUseCase(any(), any())).thenAnswer((_) async => AuthResult(
              authToken: 'token123',
              refreshAuthToken: 'refresh123',
              client: Client(id: '1', name: 'João Silva', email: 'joao@test.com'),
            ));
        when(() => createTherapistUseCase(input: any(named: 'input'))).thenAnswer((_) async => {});
        return bloc;
      },
      seed: () => const SignupInProgress(
        currentStep: 2,
        data: SignupData(
          name: 'João Silva',
          email: 'joao@test.com',
          password: 'senha123',
          legalDocument: '12345678900',
          planId: 1,
        ),
      ),
      act: (bloc) => bloc.add(const SubmitSignup()),
      expect: () => [
        const SignupLoading(
          currentStep: 2,
          data: SignupData(
            name: 'João Silva',
            email: 'joao@test.com',
            password: 'senha123',
            legalDocument: '12345678900',
            planId: 1,
          ),
        ),
        const SignupSuccess(
          currentStep: 2,
          data: SignupData(
            name: 'João Silva',
            email: 'joao@test.com',
            password: 'senha123',
            legalDocument: '12345678900',
            planId: 1,
          ),
        ),
      ],
    );

    blocTest<SignupBloc, SignupState>(
      'emite SignupFailure quando SubmitSignup falha',
      build: () {
        when(() => registerUserUseCase(any(), any())).thenThrow(Exception('Erro ao registrar'));
        return bloc;
      },
      seed: () => const SignupInProgress(
        currentStep: 2,
        data: SignupData(
          name: 'João Silva',
          email: 'joao@test.com',
          password: 'senha123',
          legalDocument: '12345678900',
          planId: 1,
        ),
      ),
      act: (bloc) => bloc.add(const SubmitSignup()),
      expect: () => [
        const SignupLoading(
          currentStep: 2,
          data: SignupData(
            name: 'João Silva',
            email: 'joao@test.com',
            password: 'senha123',
            legalDocument: '12345678900',
            planId: 1,
          ),
        ),
        SignupFailure(
          currentStep: 2,
          data: const SignupData(
            name: 'João Silva',
            email: 'joao@test.com',
            password: 'senha123',
            legalDocument: '12345678900',
            planId: 1,
          ),
          error: 'Erro ao registrar',
        ),
      ],
    );
  });
}

