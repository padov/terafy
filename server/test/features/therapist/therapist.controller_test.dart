import 'package:common/common.dart';
import 'package:mocktail/mocktail.dart';
import 'package:server/features/therapist/therapist.controller.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:test/test.dart';

class _MockTherapistRepository extends Mock implements TherapistRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(Therapist(name: 'Dr. Teste', email: 'teste@test.com', status: 'active'));
  });

  late _MockTherapistRepository therapistRepository;
  late _MockUserRepository userRepository;
  late TherapistController controller;

  final sampleTherapist = Therapist(
    id: 1,
    name: 'Dr. João Silva',
    email: 'joao@test.com',
    phone: '11999999999',
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    therapistRepository = _MockTherapistRepository();
    userRepository = _MockUserRepository();
    controller = TherapistController(therapistRepository, userRepository);
  });

  group('TherapistController - getAllTherapists', () {
    test('deve retornar lista de therapists quando sucesso', () async {
      when(
        () => therapistRepository.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true),
      ).thenAnswer((_) async => [sampleTherapist]);

      final result = await controller.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true);

      expect(result, isNotEmpty);
      expect(result.first.id, equals(1));
      expect(result.first.name, 'Dr. João Silva');
    });

    test('deve aplicar bypass RLS para admin', () async {
      when(
        () => therapistRepository.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true),
      ).thenAnswer((_) async => [sampleTherapist]);

      await controller.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true);

      verify(() => therapistRepository.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true)).called(1);
    });

    test('deve lançar TherapistException quando repository falha', () async {
      when(
        () => therapistRepository.getAllTherapists(userId: 1, userRole: 'therapist', bypassRLS: false),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () => controller.getAllTherapists(userId: 1, userRole: 'therapist', bypassRLS: false),
        throwsA(isA<TherapistException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });
  });

  group('TherapistController - getTherapistById', () {
    test('deve retornar therapist quando encontrado', () async {
      when(
        () => therapistRepository.getTherapistById(1, userId: 1, userRole: 'therapist', accountId: 1, bypassRLS: false),
      ).thenAnswer((_) async => sampleTherapist);

      final result = await controller.getTherapistById(
        1,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        bypassRLS: false,
      );

      expect(result, isNotNull);
      expect(result.id, equals(1));
      expect(result.name, 'Dr. João Silva');
    });

    test('deve lançar TherapistException quando therapist não encontrado', () async {
      when(
        () =>
            therapistRepository.getTherapistById(999, userId: 1, userRole: 'therapist', accountId: 1, bypassRLS: false),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.getTherapistById(999, userId: 1, userRole: 'therapist', accountId: 1, bypassRLS: false),
        throwsA(
          isA<TherapistException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', contains('Terapeuta não encontrado')),
        ),
      );
    });
  });

  group('TherapistController - createTherapist', () {
    test('deve criar therapist com dados válidos', () async {
      final newTherapist = Therapist(name: 'Dr. Novo', email: 'novo@test.com', status: 'active');

      when(
        () => therapistRepository.getTherapistByUserIdWithPlan(1),
      ).thenAnswer((_) async => null); // Não tem therapist ainda

      when(
        () => therapistRepository.createTherapist(newTherapist, userId: 1, userRole: 'therapist'),
      ).thenAnswer((_) async => sampleTherapist);

      when(() => therapistRepository.updateTherapistUserId(1, 1)).thenAnswer((_) async => sampleTherapist);

      when(() => userRepository.updateUserAccount(userId: 1, accountType: 'therapist', accountId: 1)).thenAnswer(
        (_) async => User(id: 1, email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active'),
      );

      final result = await controller.createTherapist(therapist: newTherapist, userId: 1, userRole: 'therapist');

      expect(result, isNotNull);
      expect(result.therapist.id, equals(1));
      verify(() => userRepository.updateUserAccount(userId: 1, accountType: 'therapist', accountId: 1)).called(1);
    });

    test('deve validar que usuário não tenha therapist já vinculado', () async {
      final newTherapist = Therapist(name: 'Dr. Novo', email: 'novo@test.com', status: 'active');

      when(
        () => therapistRepository.getTherapistByUserIdWithPlan(1),
      ).thenAnswer((_) async => {'id': 1}); // Já tem therapist

      expect(
        () => controller.createTherapist(therapist: newTherapist, userId: 1, userRole: 'therapist'),
        throwsA(
          isA<TherapistException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('já possui um perfil de terapeuta vinculado')),
        ),
      );
    });

    test('deve propagar exceção do repository quando dados inválidos', () async {
      final invalidTherapist = Therapist(
        name: '', // Nome vazio
        email: 'invalid', // Email inválido
        status: 'active',
      );

      when(() => therapistRepository.getTherapistByUserIdWithPlan(1)).thenAnswer((_) async => null);

      // O repository lança exceção quando dados são inválidos
      // O controller não captura essa exceção, então ela é propagada como está
      when(
        () => therapistRepository.createTherapist(invalidTherapist, userId: 1, userRole: 'therapist'),
      ).thenThrow(Exception('Dados inválidos'));

      // O controller não tem try-catch para createTherapist do repository,
      // então a exceção é propagada como Exception genérica
      expect(
        () => controller.createTherapist(therapist: invalidTherapist, userId: 1, userRole: 'therapist'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Dados inválidos'))),
      );
    });
  });

  group('TherapistController - updateTherapist', () {
    test('deve atualizar therapist quando encontrado', () async {
      final updatedTherapist = Therapist(
        id: sampleTherapist.id,
        name: 'Dr. João Silva Santos',
        email: sampleTherapist.email,
        phone: sampleTherapist.phone,
        status: sampleTherapist.status,
        createdAt: sampleTherapist.createdAt,
        updatedAt: DateTime.now(),
      );

      when(
        () => therapistRepository.updateTherapist(
          1,
          updatedTherapist,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => updatedTherapist);

      final result = await controller.updateTherapist(
        1,
        updatedTherapist,
        userId: 1,
        userRole: 'therapist',
        accountId: 1,
        bypassRLS: false,
      );

      expect(result.name, 'Dr. João Silva Santos');
    });

    test('deve lançar TherapistException quando therapist não encontrado', () async {
      final updatedTherapist = Therapist(
        id: sampleTherapist.id,
        name: 'Dr. João Silva Santos',
        email: sampleTherapist.email,
        phone: sampleTherapist.phone,
        status: sampleTherapist.status,
        createdAt: sampleTherapist.createdAt,
        updatedAt: DateTime.now(),
      );

      when(
        () => therapistRepository.updateTherapist(
          999,
          updatedTherapist,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
      ).thenAnswer((_) async => null);

      expect(
        () => controller.updateTherapist(
          999,
          updatedTherapist,
          userId: 1,
          userRole: 'therapist',
          accountId: 1,
          bypassRLS: false,
        ),
        throwsA(isA<TherapistException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('TherapistController - deleteTherapist', () {
    test('deve deletar therapist quando encontrado', () async {
      when(
        () => therapistRepository.deleteTherapist(1, userId: 1, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenAnswer((_) async => true);

      final result = await controller.deleteTherapist(1, userId: 1, userRole: 'admin', bypassRLS: true);

      expect(result, isTrue);
    });

    test('deve lançar TherapistException quando therapist não encontrado', () async {
      when(
        () => therapistRepository.deleteTherapist(999, userId: 1, userRole: 'admin', accountId: null, bypassRLS: true),
      ).thenAnswer((_) async => false);

      expect(
        () => controller.deleteTherapist(999, userId: 1, userRole: 'admin', bypassRLS: true),
        throwsA(isA<TherapistException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
