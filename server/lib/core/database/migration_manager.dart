import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:common/common.dart';
import 'package:server/core/config/env_config.dart';

/// Gerenciador de migrations do banco de dados
///
/// Responsável por:
/// - Criar tabela de controle de migrations
/// - Verificar quais migrations já foram executadas
/// - Executar apenas migrations pendentes
class MigrationManager {
  /// Descobre e retorna todas as migrations do diretório, ordenadas
  ///
  /// A migration de controle (que contém "create_migrations_table" no nome)
  /// será sempre a primeira, seguida das demais ordenadas alfabeticamente.
  static Future<List<String>> getAllMigrationFiles() async {
    // Tenta diferentes caminhos possíveis
    final currentDir = Directory.current.path;
    final possiblePaths = [
      '/app/db/migrations', // Docker: migrations montadas via volume (PRIMEIRO - produção)
      '/app/migrations', // Docker: migrations montadas via volume (compatibilidade)
      'migrations', // Caminho relativo simples
      '$currentDir/migrations', // Caminho relativo atual
      'server/db/migrations', // Se executado da raiz do projeto
      '$currentDir/server/db/migrations', // Caminho absoluto
      '$currentDir/../server/db/migrations', // Se executado de server/bin
    ];

    // Debug: lista diretórios tentados
    AppLogger.info('🔍 Procurando migrations. Working directory: $currentDir');
    for (final dirPath in possiblePaths) {
      final dir = Directory(dirPath);
      final exists = dir.existsSync();
      AppLogger.info('   ${exists ? '✅' : '❌'} $dirPath ${exists ? '(encontrado!)' : ''}');
    }

    Directory? migrationsDir;
    for (final dirPath in possiblePaths) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        migrationsDir = dir;
        AppLogger.info('✅ Diretório de migrations encontrado: $dirPath');
        break;
      }
    }

    if (migrationsDir == null) {
      throw Exception(
        'Diretório de migrations não encontrado. Tentou: ${possiblePaths.join(', ')}. '
        'Working directory: $currentDir',
      );
    }

    final files = migrationsDir
        .listSync()
        .whereType<File>()
        .where((file) {
          final fileName = file.path.split('/').last;
          // Ignora arquivos ocultos do macOS (._arquivo.sql) e outros arquivos não-SQL
          return fileName.endsWith('.sql') && !fileName.startsWith('._');
        })
        .map((file) => file.path.split('/').last)
        .toList();

    // Separa a migration de controle das demais
    final controlMigration = files.firstWhere((f) => f.contains('create_migrations_table'), orElse: () => '');

    final otherMigrations = files.where((f) => !f.contains('create_migrations_table')).toList();

    // Ordena as demais migrations alfabeticamente (timestamps já ordenam corretamente)
    otherMigrations.sort();

    // Retorna: migration de controle primeiro, depois as demais ordenadas
    final allMigrations = <String>[];
    if (controlMigration.isNotEmpty) {
      allMigrations.add(controlMigration);
    }
    allMigrations.addAll(otherMigrations);

    return allMigrations;
  }

  /// Garante que o banco de dados existe e tem as permissões corretas
  ///
  /// Conecta ao banco postgres (padrão) para criar o banco se necessário
  /// e garantir permissões no schema public
  ///
  /// Se não tiver permissões para criar o banco, apenas registra um aviso
  /// e continua (o banco pode já existir e o usuário pode ter acesso)
  static Future<void> ensureDatabaseAndPermissions() async {
    // Carrega configurações de ambiente
    final host = EnvConfig.getOrDefault('DB_HOST', 'localhost');
    final port = EnvConfig.getIntOrDefault('DB_PORT', 5432);
    final database = EnvConfig.getOrDefault('DB_NAME', 'terafy_db');
    final username = EnvConfig.getOrDefault('DB_USER', 'postgres');
    final password = EnvConfig.getOrDefault('DB_PASSWORD', '');

    AppLogger.info('🔍 Verificando banco de dados: $database');

    // Tenta verificar/criar o banco (pode falhar se não tiver permissão, mas continua)
    try {
      // Conecta ao banco postgres (padrão) para verificar/criar o banco
      final adminConn = await Connection.open(
        Endpoint(host: host, port: port, database: 'postgres', username: username, password: password),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      try {
        // Verifica se o banco existe
        final dbExistsResult = await adminConn.execute(
          Sql.named('SELECT EXISTS(SELECT 1 FROM pg_database WHERE datname = @database)'),
          parameters: {'database': database},
        );
        final dbExists = dbExistsResult.first.first as bool;

        if (!dbExists) {
          AppLogger.info('📦 Criando banco de dados: $database');
          try {
            await adminConn.execute('CREATE DATABASE "$database";');
            AppLogger.info('✅ Banco de dados criado: $database');
          } catch (e) {
            AppLogger.warning('⚠️  Não foi possível criar o banco (pode não ter permissão): $e');
            AppLogger.warning('   Continuando... (o banco pode já existir)');
          }
        } else {
          AppLogger.info('✅ Banco de dados já existe: $database');
        }
      } finally {
        await adminConn.close();
      }
    } catch (e) {
      AppLogger.warning('⚠️  Não foi possível verificar/criar o banco (pode não ter permissão): $e');
      AppLogger.warning('   Continuando... (o banco pode já existir e ser acessível)');
    }

    // Tenta conectar ao banco específico para garantir permissões no schema public
    Connection? dbConn;
    try {
      dbConn = await Connection.open(
        Endpoint(host: host, port: port, database: database, username: username, password: password),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      // Garante que o schema public existe e tem as permissões corretas
      AppLogger.info('🔐 Garantindo permissões no schema public...');

      try {
        // Cria o schema se não existir
        await dbConn.execute('CREATE SCHEMA IF NOT EXISTS public;');

        // Tenta garantir permissões (pode falhar se não tiver privilégios suficientes)
        try {
          await dbConn.execute('GRANT ALL ON SCHEMA public TO "$username";');
        } catch (e) {
          AppLogger.debug('   (Não foi possível conceder permissões no schema - pode não ser necessário)');
        }

        try {
          await dbConn.execute('GRANT ALL ON SCHEMA public TO public;');
        } catch (e) {
          AppLogger.debug('   (Não foi possível conceder permissões públicas - pode não ser necessário)');
        }

        // Tenta garantir permissões padrão (pode falhar se não tiver privilégios)
        try {
          await dbConn.execute('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO "$username";');
          await dbConn.execute('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO "$username";');
          await dbConn.execute('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO "$username";');
        } catch (e) {
          AppLogger.debug('   (Não foi possível configurar privilégios padrão - pode não ser necessário)');
        }

        AppLogger.info('✅ Verificação de permissões concluída');
      } catch (e) {
        AppLogger.warning('⚠️  Erro ao garantir permissões (continuando mesmo assim): $e');
      }

      await dbConn.close();
      dbConn = null;
    } catch (e) {
      final errorStr = e.toString();
      // Se o erro for que o banco não existe (código 3D000)
      if (errorStr.contains('3D000') || errorStr.contains('does not exist')) {
        AppLogger.error('❌ Banco de dados não existe e não foi possível criá-lo: $database');
        rethrow;
      }
      // Para outros erros (permissão, etc), apenas registra aviso e continua
      AppLogger.warning('⚠️  Erro ao verificar permissões (continuando mesmo assim): $e');
      AppLogger.warning('   (O banco pode estar acessível com permissões diferentes)');
    } finally {
      if (dbConn != null) {
        try {
          await dbConn.close();
        } catch (e) {
          // Ignora erros ao fechar conexão
        }
      }
    }
  }

  /// Garante que a tabela de controle de migrations existe
  static Future<void> ensureMigrationsTable(Connection conn) async {
    try {
      // Verifica se a tabela existe
      final result = await conn.execute('''
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'schema_migrations'
        );
      ''');

      final exists = result.first.first as bool;

      if (!exists) {
        // Cria a tabela se não existir
        await conn.execute('''
          CREATE TABLE schema_migrations (
            version VARCHAR(255) PRIMARY KEY,
            executed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
          );
        ''');

        await conn.execute('''
          CREATE INDEX idx_schema_migrations_executed_at 
          ON schema_migrations(executed_at);
        ''');

        AppLogger.info('Tabela schema_migrations criada');
      }
    } catch (e) {
      AppLogger.error('Erro ao garantir tabela schema_migrations: $e');
      rethrow;
    }
  }

  /// Retorna lista de migrations já executadas
  static Future<Set<String>> getExecutedMigrations(Connection conn) async {
    try {
      // Primeiro garante que a tabela existe
      await ensureMigrationsTable(conn);

      final result = await conn.execute('SELECT version FROM schema_migrations');
      return result.map((row) => row[0] as String).toSet();
    } catch (e) {
      // Se a tabela não existe ainda, retorna vazio
      // (será criada na próxima chamada)
      if (e.toString().contains('does not exist') ||
          e.toString().contains('relation') && e.toString().contains('not exist')) {
        return <String>{};
      }
      AppLogger.error('Erro ao buscar migrations executadas: $e');
      rethrow;
    }
  }

  /// Marca uma migration como executada
  static Future<void> markMigrationAsExecuted(Connection conn, String migrationName) async {
    try {
      await conn.execute(
        Sql.named('''
        INSERT INTO schema_migrations (version, executed_at)
        VALUES (@migrationName, CURRENT_TIMESTAMP)
        ON CONFLICT (version) DO NOTHING;
      '''),
        parameters: {'migrationName': migrationName},
      );
    } catch (e) {
      AppLogger.error('Erro ao marcar migration como executada: $e');
      rethrow;
    }
  }

  /// Executa uma migration específica
  static Future<void> executeMigration(Connection conn, String migrationName) async {
    // Descobre o diretório de migrations (usa os mesmos caminhos de getAllMigrationFiles)
    final currentDir = Directory.current.path;
    final possiblePaths = [
      '/app/db/migrations', // Docker: migrations montadas via volume (PRIMEIRO - produção)
      '/app/migrations', // Docker: migrations montadas via volume (compatibilidade)
      'migrations', // Caminho relativo simples
      '$currentDir/migrations', // Caminho relativo atual
      'server/db/migrations', // Se executado da raiz do projeto
      '$currentDir/server/db/migrations', // Caminho absoluto
      '$currentDir/../server/db/migrations', // Se executado de server/bin
    ];

    Directory? migrationsDir;
    for (final dirPath in possiblePaths) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        migrationsDir = dir;
        break;
      }
    }

    if (migrationsDir == null) {
      throw Exception(
        'Diretório de migrations não encontrado ao executar migration. '
        'Tentou: ${possiblePaths.join(', ')}. Working directory: $currentDir',
      );
    }

    // Ignora arquivos ocultos do macOS
    if (migrationName.startsWith('._')) {
      AppLogger.warning('Ignorando arquivo oculto do macOS: $migrationName');
      return;
    }

    final migrationPath = '${migrationsDir.path}/$migrationName';
    final file = File(migrationPath);

    if (!file.existsSync()) {
      throw Exception('Migration não encontrada: $migrationPath');
    }

    AppLogger.info('📄 Executando migration: $migrationName');

    try {
      final content = await file.readAsString();

      // Verifica se tem seção migrate:up
      if (!content.contains('-- migrate:up')) {
        AppLogger.warning('Migration sem seção migrate:up, pulando: $migrationName');
        return;
      }

      // Extrai apenas a seção migrate:up
      final upSection = content.split('-- migrate:up')[1].split('-- migrate:down')[0];

      // Remove comentários de linha completa (linhas que começam com --)
      // Mas mantém o conteúdo SQL intacto
      final lines = upSection.split('\n');
      final cleanedLines = <String>[];
      for (final line in lines) {
        final trimmed = line.trim();
        // Remove apenas linhas que são puramente comentários ou vazias
        if (trimmed.isEmpty || trimmed.startsWith('--')) {
          continue;
        }
        cleanedLines.add(line);
      }
      final cleanedContent = cleanedLines.join('\n');

      // Divide em comandos SQL (separados por ;)
      // Mas respeita dollar-quoted strings ($$ ou $tag$) que podem conter ;
      final commands = <String>[];
      String currentCommand = '';
      bool inDollarQuote = false;
      String? dollarTag; // null para $$, ou o tag para $tag$

      // Processa caractere por caractere para detectar dollar-quoted strings
      for (int i = 0; i < cleanedContent.length; i++) {
        final char = cleanedContent[i];
        final nextChar = i + 1 < cleanedContent.length ? cleanedContent[i + 1] : '';

        // Detecta início/fim de dollar-quoted string
        if (char == '\$') {
          // Verifica se é início de dollar-quote
          if (!inDollarQuote) {
            // Procura o próximo $ para determinar o tag
            int tagEnd = i + 1;
            while (tagEnd < cleanedContent.length && cleanedContent[tagEnd] != '\$') {
              tagEnd++;
            }
            if (tagEnd < cleanedContent.length) {
              dollarTag = cleanedContent.substring(i + 1, tagEnd);
              inDollarQuote = true;
              currentCommand += char;
              continue;
            }
          } else {
            // Verifica se é fim de dollar-quote
            final tag = dollarTag;
            if (tag != null) {
              // Verifica se o tag corresponde
              final tagStart = i + 1;
              if (tagStart + tag.length < cleanedContent.length) {
                final potentialTag = cleanedContent.substring(tagStart, tagStart + tag.length);
                if (potentialTag == tag &&
                    tagStart + tag.length < cleanedContent.length &&
                    cleanedContent[tagStart + tag.length] == '\$') {
                  // Encontrou o fim do dollar-quote
                  currentCommand += '\$' + tag + '\$';
                  i += tag.length + 1; // Pula o tag e o $
                  inDollarQuote = false;
                  dollarTag = null;
                  continue;
                }
              }
            } else {
              // É $$ simples
              if (nextChar == '\$') {
                currentCommand += '\$\$';
                i++; // Pula o próximo $
                inDollarQuote = false;
                dollarTag = null;
                continue;
              }
            }
          }
        }

        currentCommand += char;

        // Só divide por ; se não estiver dentro de dollar-quote
        if (char == ';' && !inDollarQuote) {
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

      // Executa cada comando na ordem exata
      // O driver PostgreSQL do Dart não suporta múltiplos comandos em uma única execução
      for (int i = 0; i < commands.length; i++) {
        final command = commands[i].trim();
        if (command.isEmpty) continue;

        try {
          AppLogger.info(
            'Executando comando ${i + 1}/${commands.length}: ${command.substring(0, command.length > 60 ? 60 : command.length)}...',
          );
          await conn.execute(command);
        } catch (e) {
          // Ignora erros de "já existe" para tipos ENUM e índices
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('already exists') || errorStr.contains('duplicate')) {
            AppLogger.warning(
              'Aviso: ${command.substring(0, command.length > 80 ? 80 : command.length)}... (já existe)',
            );
            continue;
          }

          // Para outros erros, sempre relança
          AppLogger.error('Erro ao executar comando SQL (${i + 1}/${commands.length}):');
          AppLogger.error('Comando: ${command.substring(0, command.length > 200 ? 200 : command.length)}...');
          AppLogger.error('Erro: $e');
          rethrow;
        }
      }

      // Marca como executada
      await markMigrationAsExecuted(conn, migrationName);
      AppLogger.info('✅ Migration executada: $migrationName');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao executar migration $migrationName: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Executa todas as migrations pendentes
  static Future<void> runPendingMigrations(Connection conn) async {
    AppLogger.info('🔄 Verificando migrations pendentes...');

    try {
      // Garante que a tabela de controle existe
      await ensureMigrationsTable(conn);

      // Descobre todas as migrations do diretório
      final allMigrations = await getAllMigrationFiles();
      AppLogger.info('Migrations encontradas no diretório: ${allMigrations.length}');

      // Busca migrations já executadas
      final executedMigrations = await getExecutedMigrations(conn);
      AppLogger.info('Migrations já executadas: ${executedMigrations.length}');

      // Filtra migrations pendentes
      final pendingMigrations = allMigrations.where((migration) => !executedMigrations.contains(migration)).toList();

      if (pendingMigrations.isEmpty) {
        AppLogger.info('✅ Nenhuma migration pendente');
      } else {
        AppLogger.info('📦 Executando ${pendingMigrations.length} migration(s) pendente(s)...');

        // Executa cada migration pendente
        for (final migration in pendingMigrations) {
          await executeMigration(conn, migration);
        }

        AppLogger.info('✅ Todas as migrations foram executadas com sucesso!');
      }

      // Sempre recria todas as functions, triggers e policies após verificar migrations
      // Isso garante que qualquer alteração nos arquivos seja aplicada ao banco
      await _recreateFunctionsTriggersPolicies(conn);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao executar migrations: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Recria todas as functions, triggers e policies após migrations
  ///
  /// Executa todos os arquivos SQL das pastas:
  /// - functions/ (ordem alfabética)
  /// - triggers/ (ordem alfabética)
  /// - policies/ (ordem alfabética)
  ///
  /// Antes de recriar, apaga todas as existentes para garantir limpeza completa
  static Future<void> _recreateFunctionsTriggersPolicies(Connection conn) async {
    final currentDir = Directory.current.path;
    final possibleBasePaths = [
      '/app/db', // Docker
      'server/db', // Se executado da raiz do projeto
      '$currentDir/server/db', // Caminho absoluto
      '$currentDir/../db', // Se executado de server/bin
      'db', // Caminho relativo
    ];

    Directory? baseDir;
    for (final path in possibleBasePaths) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        baseDir = dir;
        break;
      }
    }

    if (baseDir == null) {
      AppLogger.warning('⚠️  Diretório db não encontrado. Pulando recriação de functions/triggers/policies.');
      return;
    }

    try {
      // Primeiro, apaga todas as existentes para garantir limpeza completa
      AppLogger.info('🧹 Limpando functions, triggers e policies existentes...');
      await _dropAllFunctionsTriggersPolicies(conn);

      // Depois, recria tudo
      // 1. Recriar Functions
      await _recreateFromDirectory(conn, Directory('${baseDir.path}/functions'), 'functions');

      // 2. Recriar Triggers
      await _recreateFromDirectory(conn, Directory('${baseDir.path}/triggers'), 'triggers');

      // 3. Recriar Policies
      await _recreateFromDirectory(conn, Directory('${baseDir.path}/policies'), 'policies');

      AppLogger.info('✅ Recriação de functions/triggers/policies concluída!');
    } catch (e) {
      // Log mas não falha a migration - pode ser que ainda não existam as pastas
      AppLogger.warning('⚠️  Não foi possível recriar functions/triggers/policies: $e');
      AppLogger.warning('   (Isso é normal se as pastas ainda não foram criadas)');
    }
  }

  /// Apaga todas as functions, triggers e policies do schema public
  ///
  /// Isso garante uma limpeza completa antes de recriar tudo
  static Future<void> _dropAllFunctionsTriggersPolicies(Connection conn) async {
    try {
      // 1. Apaga todos os triggers primeiro (dependem de functions)
      AppLogger.info('  🗑️  Apagando triggers...');
      final triggersResult = await conn.execute('''
        SELECT 
          trigger_schema,
          event_object_table,
          trigger_name
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
        AND event_object_table != 'schema_migrations';
      ''');

      for (final row in triggersResult) {
        final schemaName = row[0] as String;
        final tableName = row[1] as String;
        final triggerName = row[2] as String;
        try {
          await conn.execute('DROP TRIGGER IF EXISTS "$triggerName" ON "$schemaName"."$tableName" CASCADE;');
        } catch (e) {
          // Ignora erros de trigger já apagado
          AppLogger.debug('    (trigger $triggerName já estava apagado)');
        }
      }

      // 2. Apaga todas as policies
      AppLogger.info('  🗑️  Apagando policies...');
      final policiesResult = await conn.execute('''
        SELECT 
          schemaname, 
          tablename, 
          policyname 
        FROM pg_policies
        WHERE schemaname = 'public';
      ''');

      for (final row in policiesResult) {
        final schemaName = row[0] as String;
        final tableName = row[1] as String;
        final policyName = row[2] as String;
        try {
          await conn.execute('DROP POLICY IF EXISTS "$policyName" ON "$schemaName"."$tableName";');
        } catch (e) {
          // Ignora erros de policy já apagada
          AppLogger.debug('    (policy $policyName já estava apagada)');
        }
      }

      // 3. Apaga todas as functions do owner (exceto system functions)
      AppLogger.info('  🗑️  Apagando functions...');
      final functionsResult = await conn.execute('''
        SELECT 
          p.proname as function_name,
          pg_get_function_identity_arguments(p.oid) as function_args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND p.proname NOT LIKE 'pg_%'
        AND p.proname NOT LIKE 'sql_%';
      ''');

      for (final row in functionsResult) {
        final functionName = row[0] as String;
        final functionArgs = row[1] as String?;
        try {
          // Se functionArgs for null ou vazio, não passa argumentos
          final args = (functionArgs == null || functionArgs.isEmpty) ? '' : '($functionArgs)';
          await conn.execute('DROP FUNCTION IF EXISTS "$functionName"$args CASCADE;');
        } catch (e) {
          // Ignora erros de function já apagada
          AppLogger.debug('    (function $functionName já estava apagada)');
        }
      }

      AppLogger.info('  ✅ Limpeza concluída!');
    } catch (e) {
      AppLogger.warning('⚠️  Erro ao limpar functions/triggers/policies (continuando mesmo assim): $e');
      // Não relança o erro - continua mesmo se houver problemas na limpeza
    }
  }

  /// Executa todos os arquivos SQL de um diretório na ordem alfabética
  static Future<void> _recreateFromDirectory(Connection conn, Directory dir, String type) async {
    if (!dir.existsSync()) {
      AppLogger.info('📁 Diretório $type não existe. Pulando...');
      return;
    }

    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.sql'))
            .where((f) => !f.path.split('/').last.startsWith('._')) // Ignora arquivos ocultos
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)); // Ordem alfabética

    if (files.isEmpty) {
      AppLogger.info('📭 Nenhum arquivo encontrado em $type/.');
      return;
    }

    AppLogger.info('🔄 Recriando ${files.length} arquivo(s) de $type...');

    for (final file in files) {
      final fileName = file.path.split('/').last;
      AppLogger.info('  📄 Executando: $fileName');

      try {
        final content = await file.readAsString();
        if (content.trim().isEmpty) {
          continue;
        }

        // Usa a mesma lógica de split de comandos do executeMigration
        final commands = _splitSqlCommands(content);

        for (final command in commands) {
          if (command.trim().isEmpty) continue;

          try {
            await conn.execute(command);
          } catch (e) {
            final errorStr = e.toString().toLowerCase();
            // CREATE OR REPLACE não gera erro se já existe, mas outros podem
            if (errorStr.contains('already exists') || errorStr.contains('duplicate')) {
              final errorMessage = e.toString();
              final truncated = errorMessage.length > 100 ? '${errorMessage.substring(0, 100)}...' : errorMessage;
              AppLogger.warning('    ⚠️  Aviso: $truncated');
              continue;
            }
            // Para outros erros, relança
            AppLogger.error('    ❌ Erro ao executar: ${e.toString()}');
            rethrow;
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('❌ Erro ao processar arquivo $fileName: $e');
        AppLogger.error('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  /// Divide SQL em comandos individuais (reutiliza lógica do executeMigration)
  static List<String> _splitSqlCommands(String sql) {
    final commands = <String>[];
    String currentCommand = '';
    bool inDollarQuote = false;
    String? dollarTag;

    for (int i = 0; i < sql.length; i++) {
      final char = sql[i];

      // Detecta dollar-quotes ($$, $tag$, etc)
      if (char == '\$' && i < sql.length - 1) {
        final nextChars = sql.substring(i);
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

      // Só divide por ; se não estiver dentro de dollar-quote
      if (char == ';' && !inDollarQuote) {
        final cmd = currentCommand.trim();
        if (cmd.isNotEmpty && cmd != ';') {
          commands.add(cmd);
        }
        currentCommand = '';
      }
    }

    final lastCmd = currentCommand.trim();
    if (lastCmd.isNotEmpty) {
      commands.add(lastCmd);
    }

    return commands;
  }
}
