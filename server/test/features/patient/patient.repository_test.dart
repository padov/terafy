import 'package:test/test.dart';
import 'package:server/features/patient/patient.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:common/common.dart';
import '../../helpers/integration_test_db.dart';

void main() {
  setUpAll(() async {
    await IntegrationTestDB.setup();
  });

  tearDownAll(() async {
    await TestDBConnection.closeAllConnections();
  });

  group('PatientRepository - Integração com Banco', () {
    late PatientRepository repository;
    late TherapistRepository therapistRepository;
    late UserRepository userRepository;
    late TestDBConnection dbConnection;

    int? testUserId;
    int? testTherapistId;
    int? testUserId2;
    int? testTherapistId2;
    int? testPatientUserId;

    setUp(() async {
      await IntegrationTestDB.cleanDatabase();
      await Future.delayed(const Duration(milliseconds: 100));

      dbConnection = TestDBConnection();
      repository = PatientRepository(dbConnection);
      therapistRepository = TherapistRepository(dbConnection);
      userRepository = UserRepository(dbConnection);

      // Gera emails únicos para evitar conflitos
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final random1 = (timestamp % 1000000).toString().padLeft(6, '0');
      final random2 = ((timestamp + 1) % 1000000).toString().padLeft(6, '0');
      final random3 = ((timestamp + 2) % 1000000).toString().padLeft(6, '0');
      final uniqueEmail1 = 'therapist1_${random1}@terafy.com';
      final uniqueEmail2 = 'therapist2_${random2}@terafy.com';
      final uniqueEmail3 = 'patient_${random3}@terafy.com';

      // Cria usuário therapist 1
      final user1 = await userRepository.createUser(
        User(
          email: uniqueEmail1,
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId = user1.id;

      // Cria therapist 1
      final therapist1 = await therapistRepository.createTherapist(
        Therapist(
          name: 'Dr. Teste 1',
          email: uniqueEmail1,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        userId: testUserId!,
        userRole: 'therapist',
      );
      testTherapistId = therapist1.id;

      // Cria usuário therapist 2
      final user2 = await userRepository.createUser(
        User(
          email: uniqueEmail2,
          passwordHash: 'hash',
          role: 'therapist',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testUserId2 = user2.id;

      // Cria therapist 2
      final therapist2 = await therapistRepository.createTherapist(
        Therapist(
          name: 'Dr. Teste 2',
          email: uniqueEmail2,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        userId: testUserId2!,
        userRole: 'therapist',
      );
      testTherapistId2 = therapist2.id;

      // Cria usuário patient
      final patientUser = await userRepository.createUser(
        User(
          email: uniqueEmail3,
          passwordHash: 'hash',
          role: 'patient',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      testPatientUserId = patientUser.id;

      expect(testUserId, isNotNull);
      expect(testTherapistId, isNotNull);
      expect(testUserId2, isNotNull);
      expect(testTherapistId2, isNotNull);
      expect(testPatientUserId, isNotNull);
    });

    tearDown(() async {
      await IntegrationTestDB.cleanDatabase();
    });

    group('getPatients', () {
      test('lista todos os pacientes (admin com bypassRLS)', () async {
        // Cria pacientes para diferentes therapists
        await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente 1', email: 'p1@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'admin',
          accountId: testTherapistId!,
          bypassRLS: true,
        );

        await repository.createPatient(
          Patient(therapistId: testTherapistId2!, fullName: 'Paciente 2', email: 'p2@test.com', status: 'active'),
          userId: testUserId2!,
          userRole: 'admin',
          accountId: testTherapistId2!,
          bypassRLS: true,
        );

        final patients = await repository.getPatients(
          userId: testUserId!,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        );

        expect(patients.length, greaterThanOrEqualTo(2));
      });

      test('lista pacientes de um therapist específico', () async {
        await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente 1', email: 'p1@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente 2', email: 'p2@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final patients = await repository.getPatients(
          therapistId: testTherapistId!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(patients.length, equals(2));
        expect(patients.every((p) => p.therapistId == testTherapistId), isTrue);
      });

      test('respeita RLS (therapist só vê seus pacientes)', () async {
        // Gera emails únicos para garantir isolamento
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final random1 = (timestamp % 1000000).toString().padLeft(6, '0');
        final random2 = ((timestamp + 1) % 1000000).toString().padLeft(6, '0');

        // Cria paciente para therapist 1
        await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Therapist 1',
            email: 'rls_p1_$random1@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        // Cria paciente para therapist 2
        await repository.createPatient(
          Patient(
            therapistId: testTherapistId2!,
            fullName: 'Paciente Therapist 2',
            email: 'rls_p2_$random2@test.com',
            status: 'active',
          ),
          userId: testUserId2!,
          userRole: 'therapist',
          accountId: testTherapistId2!,
          bypassRLS: false,
        );

        // Therapist 1 só vê seu paciente (RLS deve bloquear o paciente do therapist 2)
        final patients1 = await repository.getPatients(
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        // Verifica que só vê pacientes do seu therapist
        expect(
          patients1.length,
          equals(1),
          reason:
              'Therapist 1 deve ver apenas 1 paciente (o seu). '
              'Recebidos: ${patients1.map((p) => 'id=${p.id}, therapistId=${p.therapistId}').join(", ")}',
        );
        expect(patients1.first.therapistId, equals(testTherapistId));
        expect(patients1.first.email, contains('rls_p1_'));
      });

      test('retorna lista vazia quando não há pacientes', () async {
        final patients = await repository.getPatients(
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(patients, isEmpty);
      });

      test('ordena por created_at DESC', () async {
        final now = DateTime.now();

        await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente 1',
            email: 'p1@test.com',
            status: 'active',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente 2',
            email: 'p2@test.com',
            status: 'active',
            createdAt: now,
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final patients = await repository.getPatients(
          therapistId: testTherapistId!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(patients.length, equals(2));
        expect(patients.first.fullName, equals('Paciente 2')); // Mais recente primeiro
      });
    });

    group('getPatientById', () {
      test('retorna paciente quando encontrado', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente Teste', email: 'teste@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final found = await repository.getPatientById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(found, isNotNull);
        expect(found!.id, equals(created.id));
        expect(found.fullName, equals('Paciente Teste'));
      });

      test('retorna null quando não encontrado', () async {
        final found = await repository.getPatientById(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(found, isNull);
      });

      test('respeita RLS (therapist só acessa seus pacientes)', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Therapist 1',
            email: 'p1@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        // Therapist 2 não pode acessar paciente de therapist 1
        final found = await repository.getPatientById(
          created.id!,
          userId: testUserId2!,
          userRole: 'therapist',
          accountId: testTherapistId2!,
          bypassRLS: false,
        );

        expect(found, isNull);
      });

      test('admin pode acessar qualquer paciente (bypassRLS)', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente Teste', email: 'teste@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final found = await repository.getPatientById(
          created.id!,
          userId: testUserId!,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        );

        expect(found, isNotNull);
        expect(found!.id, equals(created.id));
      });
    });

    group('createPatient', () {
      test('cria paciente com sucesso', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Novo',
          email: 'novo@test.com',
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.id, isNotNull);
        expect(created.fullName, equals('Paciente Novo'));
        expect(created.email, equals('novo@test.com'));
        expect(created.therapistId, equals(testTherapistId));
        expect(created.status, equals('active'));
        expect(created.createdAt, isNotNull);
        expect(created.updatedAt, isNotNull);
      });

      test('cria paciente com todos os campos opcionais', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Completo',
          email: 'completo@test.com',
          birthDate: DateTime(1990, 1, 1),
          age: 34,
          cpf: '12345678900',
          rg: '123456789',
          gender: 'M',
          maritalStatus: 'single',
          address: 'Rua Teste, 123',
          phones: ['11999999999', '11888888888'],
          profession: 'Engenheiro',
          education: 'Superior',
          emergencyContact: {'name': 'Contato', 'phone': '11777777777'},
          legalGuardian: {'name': 'Tutor', 'phone': '11666666666'},
          healthInsurance: 'Unimed',
          healthInsuranceCard: '123456',
          preferredPaymentMethod: 'credit',
          sessionPrice: 150.0,
          consentSignedAt: DateTime.now(),
          lgpdConsentAt: DateTime.now(),
          status: 'active',
          treatmentStartDate: DateTime.now(),
          tags: ['tag1', 'tag2'],
          notes: 'Notas do paciente',
          photoUrl: 'https://example.com/photo.jpg',
          color: '#FF0000',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.id, isNotNull);
        // Compara apenas a parte da data (ano, mês, dia) ignorando timezone
        expect(created.birthDate, isNotNull);
        expect(created.birthDate!.year, equals(1990));
        expect(created.birthDate!.month, equals(1));
        expect(created.birthDate!.day, equals(1));
        expect(created.age, equals(34));
        expect(created.cpf, equals('12345678900'));
        expect(created.phones, equals(['11999999999', '11888888888']));
        expect(created.emergencyContact, equals({'name': 'Contato', 'phone': '11777777777'}));
        expect(created.legalGuardian, equals({'name': 'Tutor', 'phone': '11666666666'}));
        expect(created.tags, equals(['tag1', 'tag2']));
        expect(created.sessionPrice, equals(150.0));
      });

      test('cria paciente com emergency_contact JSONB', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente JSON',
          email: 'json@test.com',
          emergencyContact: {'name': 'João Silva', 'phone': '11999999999', 'relationship': 'Pai'},
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.emergencyContact, isNotNull);
        expect(created.emergencyContact!['name'], equals('João Silva'));
        expect(created.emergencyContact!['phone'], equals('11999999999'));
      });

      test('cria paciente com legal_guardian JSONB', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Menor',
          email: 'menor@test.com',
          legalGuardian: {'name': 'Maria Silva', 'phone': '11888888888', 'cpf': '98765432100'},
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.legalGuardian, isNotNull);
        expect(created.legalGuardian!['name'], equals('Maria Silva'));
      });

      test('cria paciente com phones array', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Multi-Phone',
          email: 'multi@test.com',
          phones: ['11999999999', '11888888888', '11777777777'],
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.phones, isNotNull);
        expect(created.phones!.length, equals(3));
        expect(created.phones, contains('11999999999'));
      });

      test('cria paciente com tags array', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente Tagged',
          email: 'tagged@test.com',
          tags: ['urgente', 'retorno', 'particular'],
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.tags, isNotNull);
        expect(created.tags!.length, equals(3));
        expect(created.tags, contains('urgente'));
      });

      test('respeita RLS (therapist só cria para si)', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente RLS',
          email: 'rls@test.com',
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.therapistId, equals(testTherapistId));
      });

      test('retorna paciente com ID gerado', () async {
        final patient = Patient(
          therapistId: testTherapistId!,
          fullName: 'Paciente ID',
          email: 'id@test.com',
          status: 'active',
        );

        final created = await repository.createPatient(
          patient,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(created.id, isNotNull);
        expect(created.id, greaterThan(0));
      });
    });

    group('updatePatient', () {
      test('atualiza paciente existente', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Original',
            email: 'original@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Paciente Atualizado',
            email: 'atualizado@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated, isNotNull);
        expect(updated!.fullName, equals('Paciente Atualizado'));
        expect(updated.email, equals('atualizado@test.com'));
        expect(updated.id, equals(created.id));
      });

      test('atualiza campos opcionais', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente', email: 'teste@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Paciente',
            email: 'teste@test.com',
            age: 30,
            cpf: '12345678900',
            profession: 'Médico',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated!.age, equals(30));
        expect(updated.cpf, equals('12345678900'));
        expect(updated.profession, equals('Médico'));
      });

      test('atualiza emergency_contact JSONB', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente', email: 'teste@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Paciente',
            email: 'teste@test.com',
            emergencyContact: {'name': 'Novo Contato', 'phone': '11999999999'},
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated!.emergencyContact, isNotNull);
        expect(updated.emergencyContact!['name'], equals('Novo Contato'));
      });

      test('atualiza phones array', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente',
            email: 'teste@test.com',
            phones: ['11999999999'],
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Paciente',
            email: 'teste@test.com',
            phones: ['11888888888', '11777777777'],
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated!.phones, isNotNull);
        expect(updated.phones!.length, equals(2));
        expect(updated.phones, contains('11888888888'));
      });

      test('retorna null quando paciente não existe', () async {
        final updated = await repository.updatePatient(
          99999,
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Inexistente',
            email: 'inexistente@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated, isNull);
      });

      test('respeita RLS (therapist só atualiza seus pacientes)', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Therapist 1',
            email: 'p1@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        // Therapist 2 não pode atualizar paciente de therapist 1
        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Tentativa Update',
            email: 'tentativa@test.com',
            status: 'active',
          ),
          userId: testUserId2!,
          userRole: 'therapist',
          accountId: testTherapistId2!,
          bypassRLS: false,
        );

        expect(updated, isNull);
      });

      test('retorna paciente com updated_at atualizado', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente', email: 'teste@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final originalUpdatedAt = created.updatedAt;
        await Future.delayed(const Duration(milliseconds: 100));

        final updated = await repository.updatePatient(
          created.id!,
          Patient(
            id: created.id,
            therapistId: testTherapistId!,
            fullName: 'Paciente Atualizado',
            email: 'teste@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(updated!.updatedAt, isNotNull);
        expect(updated.updatedAt!.isAfter(originalUpdatedAt!), isTrue);
      });
    });

    group('deletePatient', () {
      test('remove paciente existente', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Para Deletar',
            email: 'deletar@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final deleted = await repository.deletePatient(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(deleted, isTrue);

        final found = await repository.getPatientById(
          created.id!,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(found, isNull);
      });

      test('retorna false quando paciente não existe', () async {
        final deleted = await repository.deletePatient(
          99999,
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        expect(deleted, isFalse);
      });

      test('respeita RLS (therapist só remove seus pacientes)', () async {
        final created = await repository.createPatient(
          Patient(
            therapistId: testTherapistId!,
            fullName: 'Paciente Therapist 1',
            email: 'p1@test.com',
            status: 'active',
          ),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        // Therapist 2 não pode remover paciente de therapist 1
        final deleted = await repository.deletePatient(
          created.id!,
          userId: testUserId2!,
          userRole: 'therapist',
          accountId: testTherapistId2!,
          bypassRLS: false,
        );

        expect(deleted, isFalse);
      });

      test('admin pode remover qualquer paciente (bypassRLS)', () async {
        final created = await repository.createPatient(
          Patient(therapistId: testTherapistId!, fullName: 'Paciente Admin', email: 'admin@test.com', status: 'active'),
          userId: testUserId!,
          userRole: 'therapist',
          accountId: testTherapistId!,
          bypassRLS: false,
        );

        final deleted = await repository.deletePatient(
          created.id!,
          userId: testUserId!,
          userRole: 'admin',
          accountId: null,
          bypassRLS: true,
        );

        expect(deleted, isTrue);
      });
    });
  });
}
