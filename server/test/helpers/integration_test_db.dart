import 'package:postgres/postgres.dart';
import 'package:server/core/database/db_connection.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:async';

/// Helper para configurar banco de dados de teste
class IntegrationTestDB {
  static const String testDatabase = 'terafy_test_db';
  static const String testUser = 'postgres';
  static const String testPassword = 'mysecretpassword';
  static const String testHost = 'localhost';
  static const int testPort = 5432;

  // Mutex para garantir que apenas um teste limpe o banco por vez
  static Completer<void> _cleanMutex = Completer<void>()..complete();

  // Mutex e flag para garantir que setup() seja executado apenas uma vez
  static Completer<void>? _setupMutex;
  static bool _isSetupComplete = false;

  /// Cria uma conexão com o banco de teste
  static Future<Connection> createTestConnection() async {
    return await Connection.open(
      Endpoint(host: testHost, port: testPort, database: testDatabase, username: testUser, password: testPassword),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  /// Remove comentários de linha (-- ...) preservando strings
  static String _removeLineComments(String sql) {
    final lines = sql.split('\n');
    final cleanedLines = <String>[];

    for (final line in lines) {
      // Procura -- que não está dentro de string
      bool inString = false;
      int commentStart = -1;

      for (int i = 0; i < line.length - 1; i++) {
        final char = line[i];

        // Toggle string mode
        if (char == "'") {
          // Verifica se é escape ('')
          if (i + 1 < line.length && line[i + 1] == "'") {
            i++; // Pula o segundo '
            continue;
          }
          inString = !inString;
        }

        // Detecta -- fora de string
        if (!inString && char == '-' && line[i + 1] == '-') {
          commentStart = i;
          break;
        }
      }

      if (commentStart >= 0) {
        // Remove comentário mas mantém parte antes
        final beforeComment = line.substring(0, commentStart).trim();
        if (beforeComment.isNotEmpty) {
          cleanedLines.add(beforeComment);
        }
      } else {
        cleanedLines.add(line);
      }
    }

    return cleanedLines.join('\n');
  }

  /// Busca migrations automaticamente do diretório
  static Future<List<String>> _getMigrationsFromDirectory(String migrationsDir) async {
    final dir = Directory(migrationsDir);
    if (!dir.existsSync()) {
      throw Exception('Diretório de migrations não encontrado: $migrationsDir');
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .map((f) => path.basename(f.path))
        .toList();

    // Ordena por nome (assumindo que nomes são timestamps)
    files.sort();

    // Remove migrations que não devem ser executadas em testes
    return files.where((f) => !f.contains('create_app_user')).toList();
  }

  /// Executa migrations no banco de teste
  static Future<void> runMigrations() async {
    final conn = await createTestConnection();

    try {
      // Obter caminho absoluto do diretório de migrations
      final currentDir = Directory.current.path;
      String migrationsDir;

      if (currentDir.endsWith('server')) {
        migrationsDir = path.join(currentDir, 'db', 'migrations');
      } else if (currentDir.endsWith('terafy')) {
        migrationsDir = path.join(currentDir, 'server', 'db', 'migrations');
      } else {
        final serverDir = path.join(currentDir, 'server');
        if (Directory(serverDir).existsSync()) {
          migrationsDir = path.join(serverDir, 'db', 'migrations');
        } else {
          migrationsDir = path.join(currentDir, 'server', 'db', 'migrations');
        }
      }

      // Busca migrations automaticamente
      final migrations = await _getMigrationsFromDirectory(migrationsDir);

      for (final migration in migrations) {
        final file = File(path.join(migrationsDir, migration));
        if (!file.existsSync()) {
          continue;
        }
        final content = await file.readAsString();

        // Verifica se tem seção migrate:up
        String upSection;
        if (content.contains('-- migrate:up')) {
          upSection = content.split('-- migrate:up')[1].split('-- migrate:down')[0];
        } else {
          upSection = content;
        }

        // PRIMEIRO: Remove comentários de linha (-- ...) preservando strings
        final cleanedContent = _removeLineComments(upSection);

        // Parseia comandos SQL corretamente (ignorando ; dentro de strings/blocos)
        final List<String> commands = [];
        String currentCommand = '';
        bool inDollarQuote = false;
        String? dollarTag;
        bool inSingleQuote = false;

        for (int i = 0; i < cleanedContent.length; i++) {
          final char = cleanedContent[i];

          // Detecta strings simples (')
          if (char == "'" && !inDollarQuote) {
            // Verifica se é escape ('')
            if (i + 1 < cleanedContent.length && cleanedContent[i + 1] == "'") {
              currentCommand += "''";
              i++;
              continue;
            }
            inSingleQuote = !inSingleQuote;
          }

          // Detecta dollar-quotes ($$, $tag$, etc)
          if (char == '\$' && !inSingleQuote && i < cleanedContent.length - 1) {
            final nextChars = cleanedContent.substring(i);
            final match = RegExp(r'^\$([A-Za-z_][A-Za-z0-9_]*)?\$').firstMatch(nextChars);
            if (match != null) {
              final tag = match.group(0);
              if (tag == dollarTag) {
                inDollarQuote = false;
                dollarTag = null;
              } else if (!inDollarQuote) {
                inDollarQuote = true;
                dollarTag = tag;
              }
              currentCommand += char;
              continue;
            }
          }

          currentCommand += char;

          // Só divide por ; se não estiver dentro de quote
          if (char == ';' && !inDollarQuote && !inSingleQuote) {
            final cmd = currentCommand.trim();
            if (cmd.isNotEmpty && cmd != ';') {
              commands.add(cmd);
            }
            currentCommand = '';
          }
        }

        // Adiciona o último comando se não terminou com ;
        final lastCmd = currentCommand.trim();
        if (lastCmd.isNotEmpty) {
          commands.add(lastCmd);
        }

        for (final command in commands) {
          if (command.trim().isNotEmpty) {
            try {
              final cmdToExecute = command.trim();
              final finalCommand = cmdToExecute.endsWith(';') ? cmdToExecute : '$cmdToExecute;';
              await conn.execute(finalCommand);
            } catch (e) {
              final errorStr = e.toString();
              // Apenas ignora erros de "já existe" ou "duplicado"
              if (!errorStr.contains('already exists') &&
                  !errorStr.contains('duplicate') &&
                  !errorStr.contains('does not exist')) {
                print('❌ Erro crítico na migration $migration: $e');
                rethrow; // Re-lança erros críticos
              }
            }
          }
        }
      }

      // Verifica se as tabelas principais foram criadas
      final checkTables = ['users', 'therapists', 'patients'];
      for (final table in checkTables) {
        try {
          final result = await conn.execute(
            "SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table'",
          );
          if (result.isEmpty) {
            print('❌ Tabela $table NÃO foi criada!');
          }
        } catch (e) {
          print('⚠️  Erro ao verificar tabela $table: $e');
        }
      }
    } finally {
      await conn.close();
    }
  }

  /// Limpa todas as tabelas do banco de teste
  /// Usa mutex para evitar concorrência quando testes rodam em paralelo
  static Future<void> cleanDatabase() async {
    // Aguarda mutex para garantir exclusão mútua
    await _cleanMutex.future;
    final mutexCompleter = Completer<void>();
    _cleanMutex = mutexCompleter;

    try {
      final conn = await createTestConnection();

      try {
        await conn.execute('SET session_replication_role = replica;');

        final tables = [
          'anamnesis',
          'anamnesis_templates',
          'financial_transactions',
          'sessions',
          'appointments',
          'therapist_schedule_settings',
          'patients',
          'plan_subscriptions',
          'plans',
          'therapists',
          'token_blacklist',
          'refresh_tokens',
          'users',
        ];

        for (final table in tables) {
          try {
            await conn.execute('TRUNCATE TABLE $table CASCADE;');
          } catch (e) {
            if (!e.toString().contains('does not exist')) {
              print('⚠️  Erro ao limpar tabela $table: $e');
            }
          }
        }

        await conn.execute('SET session_replication_role = DEFAULT;');
      } finally {
        await conn.close();
      }
    } finally {
      // Libera mutex para próximo teste
      mutexCompleter.complete();
    }
  }

  /// Cria o banco de teste se não existir
  static Future<void> ensureTestDatabase() async {
    final adminConn = await Connection.open(
      Endpoint(host: testHost, port: testPort, database: 'postgres', username: testUser, password: testPassword),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    try {
      final result = await adminConn.execute("SELECT 1 FROM pg_database WHERE datname = '$testDatabase'");

      if (result.isEmpty) {
        await adminConn.execute('CREATE DATABASE $testDatabase');
        print('✅ Banco de teste criado: $testDatabase');
      }
    } finally {
      await adminConn.close();
    }
  }

  /// Setup completo: cria banco, executa migrations
  /// Thread-safe: garante que seja executado apenas uma vez, mesmo quando testes rodam em paralelo
  static Future<void> setup() async {
    // Se já está completo, retorna imediatamente
    if (_isSetupComplete) {
      return;
    }

    // Se já existe um setup em andamento, aguarda
    if (_setupMutex != null) {
      await _setupMutex!.future;
      return;
    }

    // Cria novo mutex para este setup
    final setupCompleter = Completer<void>();
    _setupMutex = setupCompleter;

    try {
      await ensureTestDatabase();
      await runMigrations();
      await cleanDatabase();
      _isSetupComplete = true;
    } finally {
      // Libera mutex
      setupCompleter.complete();
      _setupMutex = null;
    }
  }

  /// Teardown: limpa dados
  static Future<void> teardown() async {
    await cleanDatabase();
  }

  /// Atualiza o role de um usuário para admin (útil para testes)
  static Future<void> makeUserAdmin(String email) async {
    final conn = await createTestConnection();
    try {
      // Escapa email para prevenir SQL injection (email já vem de teste controlado)
      await conn.execute("UPDATE users SET role = 'admin'::user_role WHERE email = '$email'");
    } finally {
      await conn.close();
    }
  }
}

/// DBConnection específico para testes de integração
/// Usa um pool de conexões reutilizáveis para evitar esgotar as conexões do PostgreSQL
class TestDBConnection extends DBConnection {
  // Pool simples de conexões para testes
  static final List<Connection> _connectionPool = [];
  static final int _maxConnections = 5; // Limita o número de conexões simultâneas
  static int _currentIndex = 0;

  @override
  Future<Connection> getConnection() async {
    // Se já temos conexões no pool, reutiliza em round-robin
    if (_connectionPool.isNotEmpty) {
      final conn = _connectionPool[_currentIndex % _connectionPool.length];
      _currentIndex++;
      return conn;
    }

    // Cria conexões até o limite
    if (_connectionPool.length < _maxConnections) {
      final conn = await IntegrationTestDB.createTestConnection();
      _connectionPool.add(conn);
      return conn;
    }

    // Se chegou ao limite, reutiliza a primeira
    return _connectionPool[0];
  }

  @override
  void releaseConnection(Connection conn) {
    // Não fecha a conexão, apenas a mantém no pool para reutilização
    // As conexões serão fechadas no teardown global
  }

  /// Fecha todas as conexões do pool
  static Future<void> closeAllConnections() async {
    for (final conn in _connectionPool) {
      try {
        await conn.close();
      } catch (e) {
        // Ignora erros ao fechar conexões já fechadas
      }
    }
    _connectionPool.clear();
    _currentIndex = 0;
  }
}
