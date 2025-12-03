import 'package:test/test.dart';
import 'package:common/common.dart';
import 'helpers/test_user_repository.dart';

void main() {
  group('UserRepository', () {
    late TestUserRepository repository;

    setUp(() {
      repository = TestUserRepository();
    });

    tearDown(() {
      repository.clear();
    });

    group('getAllUsers', () {
      test('deve retornar lista vazia quando não há usuários', () async {
        final users = await repository.getAllUsers();
        expect(users, isEmpty);
      });

      test('deve retornar todos os usuários', () async {
        final user1 = User(email: 'user1@test.com', passwordHash: 'hash1', role: 'therapist', status: 'active');
        final user2 = User(email: 'user2@test.com', passwordHash: 'hash2', role: 'patient', status: 'active');

        await repository.createUser(user1);
        await repository.createUser(user2);

        final users = await repository.getAllUsers();
        expect(users.length, 2);
      });
    });

    group('getUserById', () {
      test('deve retornar usuário quando existe', () async {
        final user = User(email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active');
        final created = await repository.createUser(user);

        final found = await repository.getUserById(created.id!);
        expect(found, isNotNull);
        expect(found!.id, created.id);
        expect(found.email, 'user@test.com');
      });

      test('deve retornar null quando usuário não existe', () async {
        final found = await repository.getUserById(999);
        expect(found, isNull);
      });
    });

    group('getUserByEmail', () {
      test('deve retornar usuário quando existe', () async {
        final user = User(email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active');
        await repository.createUser(user);

        final found = await repository.getUserByEmail('user@test.com');
        expect(found, isNotNull);
        expect(found!.email, 'user@test.com');
      });

      test('deve retornar null quando usuário não existe', () async {
        final found = await repository.getUserByEmail('notfound@test.com');
        expect(found, isNull);
      });
    });

    group('createUser', () {
      test('deve criar usuário com dados válidos', () async {
        final user = User(email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active');

        final created = await repository.createUser(user);

        expect(created.id, isNotNull);
        expect(created.email, 'user@test.com');
        expect(created.role, 'therapist');
        expect(created.status, 'active');
        expect(created.createdAt, isNotNull);
        expect(created.updatedAt, isNotNull);
      });

      test('deve validar email único (lança exceção se duplicado)', () async {
        final user1 = User(email: 'user@test.com', passwordHash: 'hash1', role: 'therapist', status: 'active');
        final user2 = User(
          email: 'user@test.com', // Mesmo email
          passwordHash: 'hash2',
          role: 'patient',
          status: 'active',
        );

        await repository.createUser(user1);

        expect(
          () => repository.createUser(user2),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Email já está em uso'))),
        );
      });
    });

    group('updateUserAccount', () {
      test('deve vincular usuário a account', () async {
        final user = User(email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active');
        final created = await repository.createUser(user);

        final updated = await repository.updateUserAccount(
          userId: created.id!,
          accountType: 'therapist',
          accountId: 123,
        );

        expect(updated.accountType, 'therapist');
        expect(updated.accountId, 123);
      });

      test('deve lançar exceção quando usuário não existe', () async {
        expect(
          () => repository.updateUserAccount(userId: 999, accountType: 'therapist', accountId: 123),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Usuário não encontrado'))),
        );
      });
    });

    group('updateLastLogin', () {
      test('deve atualizar lastLoginAt', () async {
        final user = User(email: 'user@test.com', passwordHash: 'hash', role: 'therapist', status: 'active');
        final created = await repository.createUser(user);

        expect(created.lastLoginAt, isNull);

        await repository.updateLastLogin(created.id!);

        final updated = await repository.getUserById(created.id!);
        expect(updated!.lastLoginAt, isNotNull);
      });
    });
  });
}
