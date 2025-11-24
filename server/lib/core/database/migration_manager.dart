import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:common/common.dart';

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
      '/app/migrations', // Docker: migrations montadas via volume (PRIMEIRO - produção)
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
      '/app/migrations', // Docker: migrations montadas via volume (PRIMEIRO - produção)
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
        return;
      }

      AppLogger.info('📦 Executando ${pendingMigrations.length} migration(s) pendente(s)...');

      // Executa cada migration pendente
      for (final migration in pendingMigrations) {
        await executeMigration(conn, migration);
      }

      AppLogger.info('✅ Todas as migrations foram executadas com sucesso!');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao executar migrations: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
