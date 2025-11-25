import 'dart:convert';
import 'dart:io';
import 'package:common/common.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:server/core/config/env_config.dart';
import 'package:server/features/anamnesis/templates/default_template.dart';
import 'package:postgres/postgres.dart';

void main() async {
  // Carrega variáveis de ambiente
  EnvConfig.load();
  AppLogger.config(isDebugMode: true);

  AppLogger.info('🌱 Inserindo template padrão de anamnese do sistema...');

  final dbConnection = DBConnection();
  await dbConnection.initialize();

  try {
    await dbConnection.withConnection((conn) async {
      // Verifica se o template já existe
      final checkResult = await conn.execute(
        Sql.named('''
          SELECT id FROM anamnesis_templates 
          WHERE is_system = TRUE AND name = @name;
        '''),
        parameters: {
          'name': 'Anamnese Padrão - Adulto',
        },
      );

      if (checkResult.isNotEmpty) {
        AppLogger.info('⚠️  Template padrão já existe. Removendo versão antiga...');
        await conn.execute(
          Sql.named('''
            DELETE FROM anamnesis_templates 
            WHERE is_system = TRUE AND name = @name;
          '''),
          parameters: {
            'name': 'Anamnese Padrão - Adulto',
          },
        );
      }

      // Obtém a estrutura do template
      final structure = DefaultAnamnesisTemplate.getStructure();

      // Insere o template
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO anamnesis_templates (
            therapist_id,
            name,
            description,
            category,
            is_default,
            is_system,
            structure
          )
          VALUES (
            NULL,
            @name,
            @description,
            @category,
            FALSE,
            TRUE,
            CAST(@structure AS JSONB)
          )
          RETURNING id, name, category, is_system;
        '''),
        parameters: {
          'name': 'Anamnese Padrão - Adulto',
          'description':
              'Template completo baseado em boas práticas clínicas. Cobre todos os aspectos fundamentais para uma avaliação inicial completa do paciente.',
          'category': 'adult',
          'structure': jsonEncode(structure),
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        AppLogger.info('✅ Template padrão criado com sucesso!');
        AppLogger.info('   ID: ${row[0]}');
        AppLogger.info('   Nome: ${row[1]}');
        AppLogger.info('   Categoria: ${row[2]}');
        AppLogger.info('   Sistema: ${row[3]}');
        AppLogger.info('');
        AppLogger.info('📊 Seções incluídas: ${structure['sections'].length}');
        AppLogger.info('   - Dados Demográficos');
        AppLogger.info('   - Queixa Principal');
        AppLogger.info('   - Histórico Médico');
        AppLogger.info('   - Histórico Psiquiátrico');
        AppLogger.info('   - Histórico Familiar');
        AppLogger.info('   - Histórico de Desenvolvimento');
        AppLogger.info('   - Vida Social');
        AppLogger.info('   - Vida Profissional/Acadêmica');
        AppLogger.info('   - Hábitos de Vida');
        AppLogger.info('   - Sexualidade');
        AppLogger.info('   - Aspectos Legais');
        AppLogger.info('   - Expectativas');
        AppLogger.info('   - Observações Gerais');
      } else {
        AppLogger.error('❌ Erro ao criar template padrão');
      }
    });
  } catch (e, stackTrace) {
    AppLogger.error('❌ Erro ao inserir template padrão: $e');
    AppLogger.error('Stack trace: $stackTrace');
    exit(1);
  } finally {
    await dbConnection.closeAll();
  }
}

