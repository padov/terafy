import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/anamnesis/anamnesis.controller.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';
import 'package:test/test.dart';

class _MockAnamnesisRepository extends Mock implements AnamnesisRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Anamnesis(
        patientId: 1,
        therapistId: 1,
        data: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(
      AnamnesisTemplate(
        name: 'Template Teste',
        structure: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  late _MockAnamnesisRepository repository;
  late AnamnesisController controller;

  final sampleAnamnesis = Anamnesis(
    id: 1,
    patientId: 1,
    therapistId: 1,
    templateId: 1,
    data: {
      'chief_complaint': {
        'description': 'Ansiedade e insônia',
        'intensity': 7,
      },
    },
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final sampleTemplate = AnamnesisTemplate(
    id: 1,
    therapistId: 1,
    name: 'Template Padrão',
    description: 'Template de teste',
    category: 'adult',
    isDefault: false,
    isSystem: false,
    structure: {
      'sections': [
        {
          'id': 'chief_complaint',
          'title': 'Queixa Principal',
          'order': 1,
          'fields': [],
        },
      ],
    },
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    repository = _MockAnamnesisRepository();
    controller = AnamnesisController(repository);
  });

  group('AnamnesisController - Anamnese', () {
    test('getAnamnesisByPatientId retorna anamnese quando encontrada', () async {
      when(
        () => repository.getAnamnesisByPatientId(
          1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAnamnesis);

      final result = await controller.getAnamnesisByPatientId(
        1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNotNull);
      expect(result?.id, equals(sampleAnamnesis.id));
      expect(result?.patientId, equals(1));
    });

    test('getAnamnesisByPatientId retorna null quando não encontrada', () async {
      when(
        () => repository.getAnamnesisByPatientId(
          999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      final result = await controller.getAnamnesisByPatientId(
        999,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNull);
    });

    test('getAnamnesisById retorna anamnese quando encontrada', () async {
      when(
        () => repository.getAnamnesisById(
          1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAnamnesis);

      final result = await controller.getAnamnesisById(
        1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNotNull);
      expect(result?.id, equals(1));
    });

    test('createAnamnesis lança exceção quando já existe anamnese', () async {
      when(
        () => repository.getAnamnesisByPatientId(
          1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAnamnesis);

      await expectLater(
        () => controller.createAnamnesis(
          anamnesis: sampleAnamnesis,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<AnamnesisException>()
              .having((e) => e.statusCode, 'statusCode', 409),
        ),
      );
    });

    test('createAnamnesis cria anamnese quando não existe', () async {
      when(
        () => repository.getAnamnesisByPatientId(
          1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      when(
        () => repository.createAnamnesis(
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleAnamnesis);

      final result = await controller.createAnamnesis(
        anamnesis: sampleAnamnesis,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.id, equals(sampleAnamnesis.id));
      verify(
        () => repository.createAnamnesis(
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('updateAnamnesis retorna anamnese atualizada', () async {
      final updatedAnamnesis = sampleAnamnesis.copyWith(
        data: {
          'chief_complaint': {
            'description': 'Ansiedade atualizada',
            'intensity': 8,
          },
        },
        updatedAt: DateTime.now(),
      );

      when(
        () => repository.updateAnamnesis(
          1,
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedAnamnesis);

      final result = await controller.updateAnamnesis(
        1,
        anamnesis: updatedAnamnesis,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNotNull);
      expect(result?.data['chief_complaint']?['intensity'], equals(8));
    });

    test('deleteAnamnesis lança exceção quando não encontrada', () async {
      when(
        () => repository.deleteAnamnesis(
          999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => false);

      await expectLater(
        () => controller.deleteAnamnesis(
          999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<AnamnesisException>()
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('AnamnesisController - Templates', () {
    test('listTemplates retorna lista de templates', () async {
      when(
        () => repository.getTemplates(
          therapistId: 1,
          category: null,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => [sampleTemplate]);

      final result = await controller.listTemplates(
        therapistId: 1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, hasLength(1));
      expect(result.first.name, equals('Template Padrão'));
    });

    test('getTemplateById retorna template quando encontrado', () async {
      when(
        () => repository.getTemplateById(
          1,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTemplate);

      final result = await controller.getTemplateById(
        1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNotNull);
      expect(result?.id, equals(1));
      expect(result?.name, equals('Template Padrão'));
    });

    test('createTemplate cria template com sucesso', () async {
      when(
        () => repository.createTemplate(
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => sampleTemplate);

      final result = await controller.createTemplate(
        template: sampleTemplate,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result.id, equals(sampleTemplate.id));
      verify(
        () => repository.createTemplate(
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).called(1);
    });

    test('updateTemplate retorna template atualizado', () async {
      final updatedTemplate = sampleTemplate.copyWith(
        name: 'Template Atualizado',
        updatedAt: DateTime.now(),
      );

      when(
        () => repository.updateTemplate(
          1,
          any(),
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedTemplate);

      final result = await controller.updateTemplate(
        1,
        template: updatedTemplate,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
      );

      expect(result, isNotNull);
      expect(result?.name, equals('Template Atualizado'));
    });

    test('deleteTemplate lança exceção quando não encontrado', () async {
      when(
        () => repository.deleteTemplate(
          999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => false);

      await expectLater(
        () => controller.deleteTemplate(
          999,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
        ),
        throwsA(
          isA<AnamnesisException>()
              .having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });
}

