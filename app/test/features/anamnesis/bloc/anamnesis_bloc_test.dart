import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:terafy/core/domain/repositories/anamnesis_repository.dart';
import 'package:terafy/core/domain/repositories/anamnesis_template_repository.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc.dart';
import 'package:terafy/features/anamnesis/bloc/anamnesis_bloc_models.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';

class _MockAnamnesisRepository extends Mock implements AnamnesisRepository {}

class _MockAnamnesisTemplateRepository extends Mock implements AnamnesisTemplateRepository {}

void main() {
  group('AnamnesisBloc', () {
    late _MockAnamnesisRepository anamnesisRepository;
    late _MockAnamnesisTemplateRepository templateRepository;
    late AnamnesisBloc bloc;

    setUp(() {
      anamnesisRepository = _MockAnamnesisRepository();
      templateRepository = _MockAnamnesisTemplateRepository();
      bloc = AnamnesisBloc(
        anamnesisRepository: anamnesisRepository,
        templateRepository: templateRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('estado inicial é AnamnesisInitial', () {
      expect(bloc.state, const AnamnesisInitial());
    });

    blocTest<AnamnesisBloc, AnamnesisState>(
      'emite TemplatesLoaded quando LoadTemplates é adicionado',
      build: () {
        when(() => templateRepository.fetchTemplates(category: any(named: 'category'))).thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTemplates()),
      expect: () => [
        const AnamnesisLoading(),
        isA<TemplatesLoaded>(),
      ],
    );

    blocTest<AnamnesisBloc, AnamnesisState>(
      'emite AnamnesisLoaded quando LoadAnamnesisByPatientId é adicionado',
      build: () {
        when(() => anamnesisRepository.fetchAnamnesisByPatientId(any())).thenAnswer((_) async => Anamnesis(
              id: '1',
              patientId: '1',
              therapistId: '1',
              data: {},
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnamnesisByPatientId('1')),
      expect: () => [
        const AnamnesisLoading(),
        isA<AnamnesisLoaded>(),
      ],
    );

    blocTest<AnamnesisBloc, AnamnesisState>(
      'emite AnamnesisError quando LoadAnamnesisByPatientId falha',
      build: () {
        when(() => anamnesisRepository.fetchAnamnesisByPatientId(any())).thenThrow(Exception('Erro'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadAnamnesisByPatientId('1')),
      expect: () => [
        const AnamnesisLoading(),
        isA<AnamnesisError>(),
      ],
    );
  });
}

