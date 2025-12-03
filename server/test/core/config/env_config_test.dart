import 'dart:io';
import 'package:test/test.dart';
import 'package:server/core/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    late Directory tempDir;
    late String testEnvPath;

    // Nota: EnvConfig usa estado estático, então só podemos carregar uma vez
    // por processo de teste. Vamos criar um arquivo .env completo e testar
    // todos os cenários com ele.

    setUpAll(() {
      // Cria diretório temporário para testes
      tempDir = Directory.systemTemp.createTempSync('env_config_test_');
      testEnvPath = '${tempDir.path}/.env';

      // Cria arquivo .env com todas as variáveis necessárias para os testes
      final envFile = File(testEnvPath);
      envFile.writeAsStringSync('''
# String values
TEST_VAR=test_value
MY_VAR=my_value
OTHER_VAR=value

# Integer values
PORT=8080
TEST_NUM=42
NEGATIVE=-42
ZERO=0
INVALID_INT=not_a_number

# Boolean values
FLAG_TRUE_LOWER=true
FLAG_TRUE_UPPER=TRUE
FLAG_TRUE_MIXED=True
FLAG_FALSE=false
FLAG_ZERO=0
FLAG_NO=no
FLAG_ANYTHING=anything

# For getOrDefault tests
ACTUAL_VALUE=actual_value
DEBUG=true
''');

      // Carrega o arquivo .env uma única vez
      EnvConfig.load(filename: testEnvPath);
    });

    tearDownAll(() {
      // Limpa diretório temporário
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('load()', () {
      // Nota: Não podemos testar o caso de arquivo não encontrado aqui porque
      // o EnvConfig já foi carregado no setUpAll. Para testar isso, seria necessário
      // um teste isolado em um processo separado ou refatorar EnvConfig para permitir reset.

      test('deve ser idempotente (não recarregar se já carregado)', () {
        // Arrange - já carregado no setUpAll
        final originalValue = EnvConfig.get('TEST_VAR');

        // Cria um novo arquivo temporário
        final newEnvPath = '${tempDir.path}/.env.new';
        final newEnvFile = File(newEnvPath);
        newEnvFile.writeAsStringSync('TEST_VAR=modified\n');

        // Act - tenta carregar novamente
        EnvConfig.load(filename: newEnvPath);
        final afterReloadValue = EnvConfig.get('TEST_VAR');

        // Assert - valor não deve ter mudado
        expect(originalValue, equals('test_value'));
        expect(afterReloadValue, equals('test_value'));

        // Cleanup
        newEnvFile.deleteSync();
      });
    });

    group('get()', () {
      test('deve retornar valor do .env quando existe', () {
        // Act
        final result = EnvConfig.get('MY_VAR');

        // Assert
        expect(result, equals('my_value'));
      });

      test('deve retornar null quando variável não existe', () {
        // Act
        final result = EnvConfig.get('NONEXISTENT_VARIABLE');

        // Assert
        expect(result, isNull);
      });

      test('deve retornar valor do sistema quando não está no .env', () {
        // Act - PATH é uma variável de ambiente do sistema
        final result = EnvConfig.get('PATH');

        // Assert
        expect(result, isNotNull);
        expect(result, isNotEmpty);
      });
    });

    group('getOrDefault()', () {
      test('deve retornar valor quando existe', () {
        // Act
        final result = EnvConfig.getOrDefault('ACTUAL_VALUE', 'default_value');

        // Assert
        expect(result, equals('actual_value'));
      });

      test('deve retornar default quando variável não existe', () {
        // Act
        final result = EnvConfig.getOrDefault('NONEXISTENT', 'default_value');

        // Assert
        expect(result, equals('default_value'));
      });

      test('deve retornar default quando valor é null', () {
        // Act
        final result = EnvConfig.getOrDefault('NULL_VAR', 'default_value');

        // Assert
        expect(result, equals('default_value'));
      });
    });

    group('getInt() e getIntOrDefault()', () {
      test('getInt() deve converter string para int corretamente', () {
        // Act
        final result = EnvConfig.getInt('PORT');

        // Assert
        expect(result, equals(8080));
      });

      test('getInt() deve retornar null para valores não numéricos', () {
        // Act
        final result = EnvConfig.getInt('INVALID_INT');

        // Assert
        expect(result, isNull);
      });

      test('getInt() deve lidar com números negativos', () {
        // Act
        final result = EnvConfig.getInt('NEGATIVE');

        // Assert
        expect(result, equals(-42));
      });

      test('getInt() deve lidar com zero', () {
        // Act
        final result = EnvConfig.getInt('ZERO');

        // Assert
        expect(result, equals(0));
      });

      test('getInt() deve retornar null quando variável não existe', () {
        // Act
        final result = EnvConfig.getInt('NONEXISTENT_INT');

        // Assert
        expect(result, isNull);
      });

      test('getIntOrDefault() deve retornar valor quando conversão é bem-sucedida', () {
        // Act
        final result = EnvConfig.getIntOrDefault('PORT', 3000);

        // Assert
        expect(result, equals(8080));
      });

      test('getIntOrDefault() deve retornar default quando conversão falha', () {
        // Act
        final result = EnvConfig.getIntOrDefault('INVALID_INT', 9999);

        // Assert
        expect(result, equals(9999));
      });

      test('getIntOrDefault() deve retornar default quando variável não existe', () {
        // Act
        final result = EnvConfig.getIntOrDefault('NONEXISTENT_INT', 7777);

        // Assert
        expect(result, equals(7777));
      });
    });

    group('getBool() e getBoolOrDefault()', () {
      test('getBool() deve retornar true para "true" (case-insensitive)', () {
        // Act & Assert
        expect(EnvConfig.getBool('FLAG_TRUE_LOWER'), isTrue);
        expect(EnvConfig.getBool('FLAG_TRUE_UPPER'), isTrue);
        expect(EnvConfig.getBool('FLAG_TRUE_MIXED'), isTrue);
      });

      test('getBool() deve retornar false para qualquer outro valor', () {
        // Act & Assert
        expect(EnvConfig.getBool('FLAG_FALSE'), isFalse);
        expect(EnvConfig.getBool('FLAG_ZERO'), isFalse);
        expect(EnvConfig.getBool('FLAG_NO'), isFalse);
        expect(EnvConfig.getBool('FLAG_ANYTHING'), isFalse);
      });

      test('getBool() deve retornar null quando variável não existe', () {
        // Act
        final result = EnvConfig.getBool('NONEXISTENT_BOOL');

        // Assert
        expect(result, isNull);
      });

      test('getBoolOrDefault() deve retornar valor quando existe', () {
        // Act
        final result = EnvConfig.getBoolOrDefault('DEBUG', false);

        // Assert
        expect(result, isTrue);
      });

      test('getBoolOrDefault() deve retornar default quando não existe', () {
        // Act
        final result = EnvConfig.getBoolOrDefault('NONEXISTENT_BOOL', true);

        // Assert
        expect(result, isTrue);
      });

      test('getBoolOrDefault() deve retornar false quando valor não é "true"', () {
        // Act
        final result = EnvConfig.getBoolOrDefault('FLAG_FALSE', true);

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
