import 'package:server/core/database/db_connection.dart';
import 'package:server/core/services/password_service.dart';
import 'package:server/core/config/env_config.dart';
import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'package:server/features/therapist/therapist.repository.dart';
import 'package:server/features/patient/patient.repository.dart';

Future<void> main() async {
  // Carrega variáveis de ambiente
  EnvConfig.load();

  print('🔧 Criando usuários terapeutas e pacientes de teste...\n');

  final dbConnection = DBConnection();
  final userRepository = UserRepository(dbConnection);
  final therapistRepository = TherapistRepository(dbConnection);
  final patientRepository = PatientRepository(dbConnection);

  // Limpa terapeutas órfãos e duplicados antes de começar
  print('🧹 Limpando terapeutas órfãos e duplicados...');
  await dbConnection.withConnection((conn) async {
    final result = await conn.execute('''
      DELETE FROM therapists 
      WHERE user_id IS NULL 
      OR user_id NOT IN (SELECT id FROM users)
      OR document IN ('123.456.789-00', '987.654.321-00')
      RETURNING id;
    ''');
    if (result.isNotEmpty) {
      print('   ✓ ${result.length} terapeuta(s) órfão(s)/duplicado(s) deletado(s)\n');
    } else {
      print('   ✓ Nenhum terapeuta órfão/duplicado encontrado\n');
    }
  });

  // Lista de terapeutas para criar
  final therapistsData = [
    {
      'email': 'teste@terafy.app.br',
      'password': 'senha123',
      'name': 'Dr. João Silva',
      'nickname': 'João',
      'document': '123.456.789-00',
      'phone': '(11) 98765-4321',
      'birthDate': DateTime(1985, 5, 15),
      'professionalRegistryType': 'CRP',
      'professionalRegistryNumber': '06/123456',
      'specialties': ['Psicologia Clínica', 'Terapia Cognitivo-Comportamental', 'Ansiedade'],
      'education': 'Psicologia - USP, Mestrado em Psicologia Clínica - PUC-SP',
      'professionalPresentation':
          'Psicólogo clínico com mais de 10 anos de experiência em TCC. Especialista em transtornos de ansiedade e depressão.',
      'officeAddress': 'Rua das Flores, 123 - São Paulo, SP',
      'defaultSessionPrice': 200.0,
    },
    {
      'email': 'google@terafy.app.br',
      'password': 'senha123',
      'name': 'Dra. Maria Santos',
      'nickname': 'Maria',
      'document': '987.654.321-00',
      'phone': '(21) 99876-5432',
      'birthDate': DateTime(1990, 8, 22),
      'professionalRegistryType': 'CRP',
      'professionalRegistryNumber': '05/654321',
      'specialties': ['Psicologia Infantil', 'Orientação Familiar', 'TDAH'],
      'education': 'Psicologia - UFRJ, Especialização em Psicologia Infantil - UERJ',
      'professionalPresentation':
          'Psicóloga especializada em atendimento infantil e orientação familiar. Experiência com crianças e adolescentes com TDAH e dificuldades de aprendizagem.',
      'officeAddress': 'Av. Atlântica, 456 - Rio de Janeiro, RJ',
      'defaultSessionPrice': 180.0,
    },
  ];

  for (final therapistData in therapistsData) {
    try {
      final email = therapistData['email'] as String;
      final password = therapistData['password'] as String;

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📋 Processando: $email\n');

      // Verifica se o usuário já existe
      User? user = await userRepository.getUserByEmail(email);

      if (user != null) {
        print('⚠️  Usuário $email já existe (ID: ${user.id})');
      } else {
        // Cria hash da senha
        final passwordHash = PasswordService.hashPassword(password);

        // Cria o usuário SEM account_type (para evitar constraint violation)
        final newUser = User(
          email: email,
          passwordHash: passwordHash,
          role: 'therapist',
          status: 'active',
          emailVerified: true,
        );

        user = await userRepository.createUser(newUser);
        print('✅ Usuário criado com sucesso!');
        print('   📧 Email: ${user.email}');
        print('   🔑 Senha: $password');
        print('   👤 ID: ${user.id}');
      }

      print('');

      // Verifica se já existe um terapeuta para este email
      final existingTherapistData = await therapistRepository.getTherapistByUserIdWithPlan(user.id!);
      if (existingTherapistData != null) {
        print('⚠️  Terapeuta já existe para este usuário\n');
        continue;
      }

      // Cria o perfil de terapeuta
      final therapist = Therapist(
        name: therapistData['name'] as String,
        nickname: therapistData['nickname'] as String?,
        document: therapistData['document'] as String?,
        email: email,
        phone: therapistData['phone'] as String?,
        birthDate: therapistData['birthDate'] as DateTime?,
        professionalRegistryType: therapistData['professionalRegistryType'] as String?,
        professionalRegistryNumber: therapistData['professionalRegistryNumber'] as String?,
        specialties: therapistData['specialties'] as List<String>?,
        education: therapistData['education'] as String?,
        professionalPresentation: therapistData['professionalPresentation'] as String?,
        officeAddress: therapistData['officeAddress'] as String?,
        defaultSessionPrice: therapistData['defaultSessionPrice'] as double?,
        status: 'active',
      );

      final createdTherapist = await therapistRepository.createTherapist(therapist);
      print('✅ Perfil de terapeuta criado!');
      print('   🏥 Nome: ${createdTherapist.name}');
      print('   📋 CRP: ${createdTherapist.professionalRegistryNumber}');
      print('   💰 Preço padrão: R\$ ${createdTherapist.defaultSessionPrice?.toStringAsFixed(2)}');
      print('   🎯 Especialidades: ${createdTherapist.specialties?.join(", ")}\n');

      // Vincula o terapeuta ao usuário (atualiza user_id no therapist)
      await therapistRepository.updateTherapistUserId(createdTherapist.id!, user.id!);

      // Vincula o usuário ao terapeuta (atualiza account_type e account_id no user)
      await userRepository.updateUserAccount(
        userId: user.id!,
        accountType: 'therapist',
        accountId: createdTherapist.id!,
      );
      print('✅ Terapeuta vinculado ao usuário!\n');
    } catch (e) {
      print('❌ Erro ao criar terapeuta ${therapistData['email']}: $e\n');
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎉 Terapeutas criados com sucesso!\n');

  // ========================================
  // CRIAÇÃO DE PACIENTES
  // ========================================
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('👥 Criando pacientes de teste...\n');

  // Busca o terapeuta teste@terafy.app.br para vincular os pacientes
  final testeUser = await userRepository.getUserByEmail('teste@terafy.app.br');
  if (testeUser == null) {
    print('❌ Usuário teste@terafy.app.br não encontrado. Não é possível criar pacientes.\n');
  } else {
    final testeTherapistData = await therapistRepository.getTherapistByUserIdWithPlan(testeUser.id!);
    if (testeTherapistData == null) {
      print('❌ Terapeuta teste@terafy.app.br não encontrado. Não é possível criar pacientes.\n');
    } else {
      final testeTherapist = Therapist.fromMap(testeTherapistData);

      // Lista de pacientes para criar
      final patientsData = [
        {
          'fullName': 'Frida',
          'birthDate': DateTime(2015, 3, 10), // 9 anos
          'age': 9,
          'gender': 'Feminino',
          'email': 'frida.responsavel@email.com',
          'phones': ['(11) 91234-5678'],
          'address': 'Rua das Acácias, 789 - São Paulo, SP',
          'emergencyContact': {'name': 'Ana Silva', 'relationship': 'Mãe', 'phone': '(11) 91234-5678'},
          'legalGuardian': {'name': 'Ana Silva', 'cpf': '111.222.333-44', 'relationship': 'Mãe'},
          'sessionPrice': 180.0,
          'tags': ['Infantil', 'Ansiedade', 'Escola'],
          'notes':
              'Paciente infantil com dificuldades de adaptação escolar. Apresenta sintomas de ansiedade de separação.',
          'color': '#FF6B9D',
          'treatmentStartDate': DateTime(2024, 9, 15),
        },
        {
          'fullName': 'Otávio Henrique',
          'birthDate': DateTime(1988, 7, 22), // 36 anos
          'age': 36,
          'cpf': '555.666.777-88',
          'gender': 'Masculino',
          'maritalStatus': 'Casado',
          'email': 'otavio.henrique@email.com',
          'phones': ['(11) 98765-4321', '(11) 3456-7890'],
          'address': 'Av. Paulista, 1000 - São Paulo, SP',
          'profession': 'Engenheiro de Software',
          'education': 'Superior Completo',
          'emergencyContact': {'name': 'Carla Henrique', 'relationship': 'Esposa', 'phone': '(11) 98888-7777'},
          'healthInsurance': 'Unimed',
          'healthInsuranceCard': '1234567890',
          'preferredPaymentMethod': 'Cartão de Crédito',
          'sessionPrice': 200.0,
          'tags': ['Adulto', 'Burnout', 'Ansiedade'],
          'notes':
              'Paciente adulto em tratamento para síndrome de burnout. Trabalha em startup de tecnologia com alta carga de estresse.',
          'color': '#4A90E2',
          'treatmentStartDate': DateTime(2024, 6, 1),
        },
      ];

      for (final patientData in patientsData) {
        try {
          final fullName = patientData['fullName'] as String;

          print('📋 Criando paciente: $fullName');

          final patient = Patient(
            therapistId: testeTherapist.id!,
            fullName: fullName,
            birthDate: patientData['birthDate'] as DateTime?,
            age: patientData['age'] as int?,
            cpf: patientData['cpf'] as String?,
            rg: patientData['rg'] as String?,
            gender: patientData['gender'] as String?,
            maritalStatus: patientData['maritalStatus'] as String?,
            address: patientData['address'] as String?,
            email: patientData['email'] as String?,
            phones: patientData['phones'] as List<String>?,
            profession: patientData['profession'] as String?,
            education: patientData['education'] as String?,
            emergencyContact: patientData['emergencyContact'] as Map<String, dynamic>?,
            legalGuardian: patientData['legalGuardian'] as Map<String, dynamic>?,
            healthInsurance: patientData['healthInsurance'] as String?,
            healthInsuranceCard: patientData['healthInsuranceCard'] as String?,
            preferredPaymentMethod: patientData['preferredPaymentMethod'] as String?,
            sessionPrice: patientData['sessionPrice'] as double?,
            tags: patientData['tags'] as List<String>?,
            notes: patientData['notes'] as String?,
            color: patientData['color'] as String?,
            treatmentStartDate: patientData['treatmentStartDate'] as DateTime?,
            status: 'active',
          );

          final createdPatient = await patientRepository.createPatient(
            patient,
            userId: testeUser.id!,
            userRole: testeUser.role,
            accountId: testeTherapist.id,
            bypassRLS: true,
          );

          print('✅ Paciente criado!');
          print('   👤 Nome: ${createdPatient.fullName}');
          print('   🎂 Idade: ${createdPatient.age} anos');
          print('   💰 Preço da sessão: R\$ ${createdPatient.sessionPrice?.toStringAsFixed(2)}');
          print('   🏷️  Tags: ${createdPatient.tags?.join(", ")}\n');
        } catch (e) {
          print('❌ Erro ao criar paciente ${patientData['fullName']}: $e\n');
        }
      }
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🎉 Processo concluído!');
  print('🚀 Você pode fazer login com as credenciais acima!\n');
}
