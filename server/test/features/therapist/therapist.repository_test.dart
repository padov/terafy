import 'package:test/test.dart';
import 'package:common/common.dart';
import 'helpers/test_therapist_repository.dart';

void main() {
  group('TherapistRepository', () {
    late TestTherapistRepository repository;

    setUp(() {
      repository = TestTherapistRepository();
    });

    tearDown(() {
      repository.clear();
    });

    group('getAllTherapists', () {
      test('deve retornar lista vazia quando não há therapists', () async {
        final therapists = await repository.getAllTherapists();
        expect(therapists, isEmpty);
      });

      test('deve retornar todos os therapists', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final therapist2 = Therapist(name: 'Dra. Maria Santos', email: 'maria@test.com', status: 'active');

        await repository.createTherapist(therapist1);
        await repository.createTherapist(therapist2);

        final therapists = await repository.getAllTherapists();
        expect(therapists.length, 2);
        expect(therapists.any((t) => t.email == 'joao@test.com'), isTrue);
        expect(therapists.any((t) => t.email == 'maria@test.com'), isTrue);
      });

      test('deve retornar todos os therapists quando bypassRLS=true (admin)', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        await repository.createTherapist(therapist1);

        final therapists = await repository.getAllTherapists(bypassRLS: true);
        expect(therapists.length, 1);
      });

      test('deve retornar todos quando bypassRLS=true mesmo com contexto RLS', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final therapist2 = Therapist(name: 'Dra. Maria Santos', email: 'maria@test.com', status: 'active');
        await repository.createTherapist(therapist1);
        await repository.createTherapist(therapist2);

        // Com bypassRLS=true, deve retornar todos mesmo com contexto RLS
        final therapists = await repository.getAllTherapists(userId: 1, userRole: 'admin', bypassRLS: true);
        expect(therapists.length, 2);
      });
    });

    group('getTherapistById', () {
      test('deve retornar therapist quando existe (sem contexto RLS)', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        // Sem contexto RLS explícito, retorna todos (comportamento padrão para testes)
        final found = await repository.getTherapistById(created.id!);
        expect(found, isNotNull);
        expect(found!.id, created.id);
        expect(found.name, 'Dr. João Silva');
        expect(found.email, 'joao@test.com');
      });

      test('deve retornar null quando therapist não existe', () async {
        final found = await repository.getTherapistById(999);
        expect(found, isNull);
      });

      test('deve respeitar RLS (não retorna de outra conta)', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        // Com contexto RLS mas accountId diferente, não retorna
        final found = await repository.getTherapistById(
          created.id!,
          userId: 1,
          userRole: 'therapist',
          accountId: 999, // accountId diferente do therapist criado
        );
        expect(found, isNull);
      });
    });

    group('createTherapist', () {
      test('deve criar therapist com dados válidos', () async {
        final therapist = Therapist(
          name: 'Dr. João Silva',
          email: 'joao@test.com',
          phone: '11999999999',
          status: 'active',
        );

        final created = await repository.createTherapist(therapist);

        expect(created.id, isNotNull);
        expect(created.name, 'Dr. João Silva');
        expect(created.email, 'joao@test.com');
        expect(created.phone, '11999999999');
        expect(created.status, 'active');
        expect(created.createdAt, isNotNull);
        expect(created.updatedAt, isNotNull);
      });

      test('deve gerar ID automaticamente', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final therapist2 = Therapist(name: 'Dra. Maria Santos', email: 'maria@test.com', status: 'active');

        final created1 = await repository.createTherapist(therapist1);
        final created2 = await repository.createTherapist(therapist2);

        expect(created1.id, isNotNull);
        expect(created2.id, isNotNull);
        expect(created2.id, greaterThan(created1.id!));
      });

      test('deve validar email único', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final therapist2 = Therapist(
          name: 'Dra. Maria Santos',
          email: 'joao@test.com', // Mesmo email
          status: 'active',
        );

        await repository.createTherapist(therapist1);

        expect(
          () => repository.createTherapist(therapist2),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Email já está em uso'))),
        );
      });
    });

    group('updateTherapist', () {
      test('deve atualizar dados corretamente', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        final updated = Therapist(
          name: 'Dr. João Silva Santos',
          email: 'joao.santos@test.com',
          phone: '11999999999',
          status: 'active',
        );

        final result = await repository.updateTherapist(created.id!, updated, userId: 1, bypassRLS: true);

        expect(result, isNotNull);
        expect(result!.name, 'Dr. João Silva Santos');
        expect(result.email, 'joao.santos@test.com');
        expect(result.phone, '11999999999');
        expect(result.updatedAt, isNotNull);
        expect(result.updatedAt, isNot(equals(created.updatedAt)));
      });

      test('deve retornar null quando therapist não existe', () async {
        final updated = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');

        final result = await repository.updateTherapist(999, updated, userId: 1, bypassRLS: true);

        expect(result, isNull);
      });

      test('deve respeitar RLS', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        final updated = Therapist(name: 'Dr. João Silva Santos', email: 'joao.santos@test.com', status: 'active');

        // Com contexto RLS mas accountId diferente, não atualiza (RLS bloqueia)
        final result = await repository.updateTherapist(
          created.id!,
          updated,
          userId: 1,
          userRole: 'therapist',
          accountId: 999, // accountId diferente do therapist criado
        );
        expect(result, isNull);
      });

      test('deve validar email único ao atualizar', () async {
        final therapist1 = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final therapist2 = Therapist(name: 'Dra. Maria Santos', email: 'maria@test.com', status: 'active');

        final created1 = await repository.createTherapist(therapist1);
        await repository.createTherapist(therapist2);

        final updated = Therapist(
          name: 'Dr. João Silva',
          email: 'maria@test.com', // Email já usado por outro therapist
          status: 'active',
        );

        expect(
          () => repository.updateTherapist(created1.id!, updated, userId: 1, bypassRLS: true),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Email já está em uso'))),
        );
      });
    });

    group('deleteTherapist', () {
      test('deve remover therapist corretamente', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        final deleted = await repository.deleteTherapist(created.id!, userId: 1, bypassRLS: true);

        expect(deleted, isTrue);

        final found = await repository.getTherapistById(created.id!, bypassRLS: true);
        expect(found, isNull);
      });

      test('deve retornar false quando therapist não existe', () async {
        final deleted = await repository.deleteTherapist(999, userId: 1, bypassRLS: true);
        expect(deleted, isFalse);
      });

      test('deve respeitar RLS', () async {
        final therapist = Therapist(name: 'Dr. João Silva', email: 'joao@test.com', status: 'active');
        final created = await repository.createTherapist(therapist);

        // Com contexto RLS mas accountId diferente, não deleta (RLS bloqueia)
        final deleted = await repository.deleteTherapist(
          created.id!,
          userId: 1,
          userRole: 'therapist',
          accountId: 999, // accountId diferente do therapist criado
        );
        expect(deleted, isFalse);
      });
    });
  });
}
