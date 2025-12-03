import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/usecases/therapist/get_current_therapist_usecase.dart';
import 'package:terafy/core/domain/usecases/therapist/update_therapist_usecase.dart';
import 'package:terafy/features/profile/edit_profile_bloc.dart';
import 'package:terafy/features/profile/edit_profile_bloc_models.dart';

class _MockGetCurrentTherapistUseCase extends Mock implements GetCurrentTherapistUseCase {}

class _MockUpdateTherapistUseCase extends Mock implements UpdateTherapistUseCase {}

void main() {
  group('EditProfileBloc', () {
    late _MockGetCurrentTherapistUseCase getCurrentTherapistUseCase;
    late _MockUpdateTherapistUseCase updateTherapistUseCase;
    late EditProfileBloc bloc;

    setUp(() {
      getCurrentTherapistUseCase = _MockGetCurrentTherapistUseCase();
      updateTherapistUseCase = _MockUpdateTherapistUseCase();
      bloc = EditProfileBloc(
        getCurrentTherapistUseCase: getCurrentTherapistUseCase,
        updateTherapistUseCase: updateTherapistUseCase,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é EditProfileInitial', () {
      expect(bloc.state, const EditProfileInitial());
    });

    blocTest<EditProfileBloc, EditProfileState>(
      'emite EditProfileLoaded quando LoadProfileData é adicionado',
      build: () {
        when(() => getCurrentTherapistUseCase()).thenAnswer((_) async => {
              'id': 1,
              'name': 'Dr. João Silva',
              'email': 'joao@test.com',
              'phone': '11999999999',
            });
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadProfileData()),
      expect: () => [
        const EditProfileLoading(currentStep: 0, data: EditProfileData()),
        isA<EditProfileLoaded>(),
      ],
    );

    blocTest<EditProfileBloc, EditProfileState>(
      'atualiza dados pessoais quando UpdatePersonalData é adicionado',
      build: () => bloc,
      seed: () => const EditProfileLoaded(
        currentStep: 0,
        data: EditProfileData(),
      ),
      act: (bloc) => bloc.add(
        const UpdatePersonalData(
          name: 'Dr. João Silva',
          nickname: 'João',
          legalDocument: '12345678900',
          email: 'joao@test.com',
          phone: '11999999999',
        ),
      ),
      expect: () => [
        const EditProfileInProgress(
          currentStep: 0,
          data: EditProfileData(
            name: 'Dr. João Silva',
            nickname: 'João',
            legalDocument: '12345678900',
            email: 'joao@test.com',
            phone: '11999999999',
          ),
        ),
      ],
    );

    blocTest<EditProfileBloc, EditProfileState>(
      'emite EditProfileSuccess quando SubmitEditProfile é adicionado',
      build: () {
        when(() => updateTherapistUseCase(therapist: any(named: 'therapist'))).thenAnswer((_) async => {
              'id': 1,
              'name': 'Dr. João Silva',
            });
        return bloc;
      },
      seed: () => const EditProfileInProgress(
        currentStep: 1,
        data: EditProfileData(
          name: 'Dr. João Silva',
          email: 'joao@test.com',
        ),
      ),
      act: (bloc) => bloc.add(const SubmitEditProfile()),
      expect: () => [
        const EditProfileSaving(
          currentStep: 1,
          data: EditProfileData(
            name: 'Dr. João Silva',
            email: 'joao@test.com',
          ),
        ),
        isA<EditProfileSuccess>(),
      ],
    );
  });
}

