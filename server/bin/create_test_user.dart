import 'package:server/core/database/db_connection.dart';
import 'package:server/core/services/password_service.dart';
import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';

Future<void> main() async {
  print('🔧 Criando usuário de teste...\n');

  final dbConnection = DBConnection();
  final userRepository = UserRepository(dbConnection);

  try {
    final email = 'teste@terafy.com';
    final password = 'senha123';

    // Verifica se o usuário já existe
    final existingUser = await userRepository.getUserByEmail(email);
    if (existingUser != null) {
      print('⚠️  Usuário $email já existe!');
      print('ID: ${existingUser.id}');
      print('Role: ${existingUser.role}');
      print('Status: ${existingUser.status}');
      return;
    }

    // Cria hash da senha
    final passwordHash = PasswordService.hashPassword(password);

    // Cria o usuário
    final newUser = User(
      email: email,
      passwordHash: passwordHash,
      role: 'therapist',
      accountType: 'therapist',
      status: 'active',
      emailVerified: true,
    );

    final createdUser = await userRepository.createUser(newUser);

    print('✅ Usuário criado com sucesso!\n');
    print('📧 Email: ${createdUser.email}');
    print('🔑 Senha: $password');
    print('👤 ID: ${createdUser.id}');
    print('🎭 Role: ${createdUser.role}');
    print('📊 Status: ${createdUser.status}\n');
    print('🚀 Agora você pode fazer login com essas credenciais!');
  } catch (e) {
    print('❌ Erro ao criar usuário: $e');
  }
}
