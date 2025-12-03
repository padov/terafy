import 'package:test/test.dart';
import 'package:common/common.dart';
import 'package:server/features/anamnesis/anamnesis.repository.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/features/user/user.repository.dart';
import '../../helpers/integration_test_db.dart';

void main() {
  group('AnamnesisRepository - Integração com Banco', () {
    late AnamnesisRepository repository;
    late PatientRepository patientRepository;
    late TherapistRepository therapistRepository;
    late UserRepository userRepository;
    late TestDBConnection dbConnection;

    int? testUserId;
    int? testTherapistId;
    int? testPatientId;

    setUpAll(() async {
      await IntegrationTestDB.setup();
    });

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      dbConnection = TestDBConnection();
      repository = AnamnesisRepository(dbConnection);
      patientRepository = PatientRepository(dbConnection);
      therapistRepository = TherapistRepository(dbConnection);
      userRepository = UserRepository(dbConnection);

      // Cria usuário
      final user = await userRepository.createUser(
        User(
          email: 'therapist@test.com',
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId = user.id;

      // Cria therapist
      final therapist = await therapistRepository.createTherapist(
        Therapist(
          name: 'Dr. Teste',
          email: 'therapist@test.com',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        userId: testUserId!,
        userRole: 'therapist',
      );
      testTherapistId = therapist.id;

      // Cria patient
      final patient = await patientRepository.createPatient(
        Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Teste',
          email: 'paciente@test.com',
          phones: ['11999999999'],
          birthDate: DateTime(1990, 1, 1),
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        userId: testUserId!,
        userRole: 'therapist',
        accountId: testTherapistId!,
        bypassRLS: true,
      );
      testPatientId = patient.id;
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('Anamnese CRUD', () {
      test('getAnamnesisByPatientId retorna anamnese quando encontrada', () async {
        // Cria anamnese
        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          data: {'test': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createAnamnesis(
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Busca por patientId
        final found = await repository.getAnamnesisByPatientId(
          testPatientId!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNotNull);
        expect(found?.id, equals(created.id));
        expect(found?.patientId, equals(testPatientId));
        expect(found?.data['test'], equals('value'));
      });

      test('getAnamnesisByPatientId retorna null quando não encontrada', () async {
        final found = await repository.getAnamnesisByPatientId(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNull);
      });

      test('getAnamnesisById retorna anamnese quando encontrada', () async {
        // Garante que os dados necessários foram criados
        expect(testPatientId, isNotNull, reason: 'Patient ID deve estar disponível');
        expect(testTherapistId, isNotNull, reason: 'Therapist ID deve estar disponível');
        expect(testUserId, isNotNull, reason: 'User ID deve estar disponível');

        // Cria anamnese
        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          data: {'test': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createAnamnesis(
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Busca por ID
        final found = await repository.getAnamnesisById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNotNull);
        expect(found?.id, equals(created.id));
      });

      test('getAnamnesisById retorna null quando não encontrada', () async {
        final found = await repository.getAnamnesisById(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNull);
      });

      test('createAnamnesis cria anamnese com sucesso', () async {
        // Garante que os dados necessários foram criados
        expect(testPatientId, isNotNull, reason: 'Patient ID deve estar disponível');
        expect(testTherapistId, isNotNull, reason: 'Therapist ID deve estar disponível');
        expect(testUserId, isNotNull, reason: 'User ID deve estar disponível');

        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          templateId: null,
          data: {
            'chief_complaint': {'description': 'Ansiedade e insônia', 'intensity': 7},
          },
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createAnamnesis(
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(created.id, isNotNull);
        expect(created.patientId, equals(testPatientId));
        expect(created.therapistId, equals(testTherapistId));
        expect(created.data['chief_complaint']?['intensity'], equals(7));
      });

      test('updateAnamnesis atualiza anamnese com sucesso', () async {
        // Cria anamnese
        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          data: {'old': 'value'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createAnamnesis(
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Atualiza
        final updatedData = created.copyWith(data: {'new': 'value', 'updated': true}, completedAt: DateTime.now());

        final updated = await repository.updateAnamnesis(
          created.id!,
          updatedData,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(updated, isNotNull);
        expect(updated?.data['new'], equals('value'));
        expect(updated?.completedAt, isNotNull);
      });

      test('updateAnamnesis retorna null quando não encontrada', () async {
        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          data: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updated = await repository.updateAnamnesis(
          99999,
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(updated, isNull);
      });

      test('deleteAnamnesis deleta anamnese com sucesso', () async {
        // Cria anamnese
        final anamnesis = Anamnesis(
          patientId: testPatientId!,
          therapistId: testTherapistId!,
          data: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createAnamnesis(
          anamnesis,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Deleta
        final deleted = await repository.deleteAnamnesis(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(deleted, isTrue);

        // Verifica que foi deletada
        final found = await repository.getAnamnesisById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNull);
      });

      test('deleteAnamnesis retorna false quando não encontrada', () async {
        final deleted = await repository.deleteAnamnesis(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(deleted, isFalse);
      });
    });

    group('Template CRUD', () {
      test('getTemplates retorna lista de templates', () async {
        // Cria template
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Teste',
          category: 'adult',
          isDefault: false,
          isSystem: false,
          structure: {'sections': []},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        final templates = await repository.getTemplates(
          therapistId: testTherapistId,
          category: null,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(templates, isNotEmpty);
        expect(templates.any((t) => t.name == 'Template Teste'), isTrue);
      });

      test('getTemplates filtra por category', () async {
        // Cria templates com categorias diferentes
        final template1 = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Adult',
          category: 'adult',
          isDefault: false,
          isSystem: false,
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final template2 = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Child',
          category: 'child',
          isDefault: false,
          isSystem: false,
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template1,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        await repository.createTemplate(
          template2,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        final templates = await repository.getTemplates(
          therapistId: testTherapistId,
          category: 'adult',
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(templates.length, greaterThanOrEqualTo(1));
        expect(templates.every((t) => t.category == 'adult'), isTrue);
      });

      test('getTemplateById retorna template quando encontrado', () async {
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Teste',
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createTemplate(
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        final found = await repository.getTemplateById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNotNull);
        expect(found?.id, equals(created.id));
        expect(found?.name, equals('Template Teste'));
      });

      test('getTemplateById retorna null quando não encontrado', () async {
        final found = await repository.getTemplateById(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNull);
      });

      test('createTemplate cria template com sucesso', () async {
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Novo Template',
          description: 'Descrição',
          category: 'adult',
          isDefault: false,
          isSystem: false,
          structure: {
            'sections': [
              {'id': 'section1', 'title': 'Seção 1', 'fields': []},
            ],
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createTemplate(
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(created.id, isNotNull);
        expect(created.name, equals('Novo Template'));
        expect(created.therapistId, equals(testTherapistId));
        expect(created.structure['sections'], isNotEmpty);
      });

      test('createTemplate remove isDefault anterior quando marca novo como padrão', () async {
        // Cria template padrão
        final template1 = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Padrão 1',
          isDefault: true,
          isSystem: false,
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created1 = await repository.createTemplate(
          template1,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Cria novo template marcado como padrão
        final template2 = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Padrão 2',
          isDefault: true,
          isSystem: false,
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.createTemplate(
          template2,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        // Verifica que o primeiro não é mais padrão
        final found1 = await repository.getTemplateById(
          created1.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found1?.isDefault, isFalse);
      });

      test('updateTemplate atualiza template com sucesso', () async {
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template Original',
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createTemplate(
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        final updatedData = created.copyWith(name: 'Template Atualizado', description: 'Nova descrição');

        final updated = await repository.updateTemplate(
          created.id!,
          updatedData,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(updated, isNotNull);
        expect(updated?.name, equals('Template Atualizado'));
        expect(updated?.description, equals('Nova descrição'));
      });

      test('updateTemplate retorna null quando não encontrado', () async {
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template',
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updated = await repository.updateTemplate(
          99999,
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(updated, isNull);
      });

      test('deleteTemplate deleta template com sucesso', () async {
        final template = AnamnesisTemplate(
          therapistId: testTherapistId,
          name: 'Template para Deletar',
          structure: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final created = await repository.createTemplate(
          template,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        final deleted = await repository.deleteTemplate(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(deleted, isTrue);

        // Verifica que foi deletado
        final found = await repository.getTemplateById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(found, isNull);
      });

      test('deleteTemplate retorna false quando não encontrado', () async {
        final deleted = await repository.deleteTemplate(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        expect(deleted, isFalse);
      });
    });

    group('Template - Proteção de templates do sistema', () {
      test('updateTemplate lança exceção ao tentar atualizar template de sistema', () async {
        // Cria template de sistema (via SQL direto, pois não há método público para isso)
        final conn = await IntegrationTestDB.createTestConnection();
        try {
          final result = await conn.execute('''
            INSERT INTO anamnesis_templates (
              therapist_id, name, is_system, structure, created_at, updated_at
            )
            VALUES (NULL, 'Template Sistema', true, '{}'::jsonb, NOW(), NOW())
            RETURNING id;
            ''');

          final systemTemplateId = (result.first[0] as int);

          final template = AnamnesisTemplate(
            id: systemTemplateId,
            therapistId: null,
            name: 'Template Sistema',
            isSystem: true,
            structure: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Tenta atualizar
          await expectLater(
            () => repository.updateTemplate(
              systemTemplateId,
              template.copyWith(name: 'Modificado'),
              userId: testUserId!,
              userRole: 'admin',
              accountId: null,
              bypassRLS: true,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Não é possível editar templates do sistema'),
              ),
            ),
          );
        } finally {
          await conn.close();
        }
      });

      test('deleteTemplate lança exceção ao tentar deletar template de sistema', () async {
        // Cria template de sistema
        final conn = await IntegrationTestDB.createTestConnection();
        try {
          final result = await conn.execute('''
            INSERT INTO anamnesis_templates (
              therapist_id, name, is_system, structure, created_at, updated_at
            )
            VALUES (NULL, 'Template Sistema', true, '{}'::jsonb, NOW(), NOW())
            RETURNING id;
            ''');

          final systemTemplateId = (result.first[0] as int);

          // Tenta deletar
          await expectLater(
            () => repository.deleteTemplate(
              systemTemplateId,
              userId: testUserId!,
              userRole: 'admin',
              accountId: null,
              bypassRLS: true,
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Não é possível deletar templates do sistema'),
              ),
            ),
          );
        } finally {
          await conn.close();
        }
      });
    });
  });
}
