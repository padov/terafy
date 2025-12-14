import 'package:test/test.dart';
import 'package:common/src/validators/document_validator.dart';

void main() {
  group('DocumentValidator', () {
    group('CPF Validation', () {
      test('should accept valid CPF without formatting', () {
        // Valid CPF: 123.456.789-09
        expect(DocumentValidator.validateDocument('12345678909'), isNull);
      });

      test('should accept valid CPF with formatting', () {
        expect(DocumentValidator.validateDocument('123.456.789-09'), isNull);
      });

      test('should accept another valid CPF', () {
        // Valid CPF: 111.444.777-35
        expect(DocumentValidator.validateDocument('11144477735'), isNull);
      });

      test('should reject CPF with invalid check digits', () {
        final result = DocumentValidator.validateDocument('12345678900');
        expect(result, isNotNull);
        expect(result, contains('CPF inválido'));
      });

      test('should reject CPF with all same digits', () {
        final result = DocumentValidator.validateDocument('11111111111');
        expect(result, isNotNull);
        expect(result, contains('CPF inválido'));
      });

      test('should reject CPF with all zeros', () {
        final result = DocumentValidator.validateDocument('00000000000');
        expect(result, isNotNull);
        expect(result, contains('CPF inválido'));
      });

      test('should reject CPF with wrong first check digit', () {
        final result = DocumentValidator.validateDocument('12345678919');
        expect(result, isNotNull);
        expect(result, contains('CPF inválido'));
      });

      test('should reject CPF with wrong second check digit', () {
        final result = DocumentValidator.validateDocument('12345678908');
        expect(result, isNotNull);
        expect(result, contains('CPF inválido'));
      });
    });

    group('CNPJ Validation', () {
      test('should accept valid CNPJ without formatting', () {
        // Valid CNPJ: 11.222.333/0001-81
        expect(DocumentValidator.validateDocument('11222333000181'), isNull);
      });

      test('should accept valid CNPJ with formatting', () {
        expect(DocumentValidator.validateDocument('11.222.333/0001-81'), isNull);
      });

      test('should accept another valid CNPJ', () {
        // Valid CNPJ: 34.028.316/0001-03
        expect(DocumentValidator.validateDocument('34028316000103'), isNull);
      });

      test('should reject CNPJ with invalid check digits', () {
        final result = DocumentValidator.validateDocument('11222333000180');
        expect(result, isNotNull);
        expect(result, contains('CNPJ inválido'));
      });

      test('should reject CNPJ with all same digits', () {
        final result = DocumentValidator.validateDocument('11111111111111');
        expect(result, isNotNull);
        expect(result, contains('CNPJ inválido'));
      });

      test('should reject CNPJ with all zeros', () {
        final result = DocumentValidator.validateDocument('00000000000000');
        expect(result, isNotNull);
        expect(result, contains('CNPJ inválido'));
      });

      test('should reject CNPJ with wrong first check digit', () {
        final result = DocumentValidator.validateDocument('11222333000191');
        expect(result, isNotNull);
        expect(result, contains('CNPJ inválido'));
      });

      test('should reject CNPJ with wrong second check digit', () {
        final result = DocumentValidator.validateDocument('11222333000182');
        expect(result, isNotNull);
        expect(result, contains('CNPJ inválido'));
      });
    });

    group('Optional Field Handling', () {
      test('should accept null document', () {
        expect(DocumentValidator.validateDocument(null), isNull);
      });

      test('should accept empty string', () {
        expect(DocumentValidator.validateDocument(''), isNull);
      });

      test('should accept whitespace-only string', () {
        expect(DocumentValidator.validateDocument('   '), isNull);
      });
    });

    group('Invalid Length', () {
      test('should reject document with 10 digits', () {
        final result = DocumentValidator.validateDocument('1234567890');
        expect(result, isNotNull);
        expect(result, contains('11 dígitos (CPF) ou 14 dígitos (CNPJ)'));
      });

      test('should reject document with 12 digits', () {
        final result = DocumentValidator.validateDocument('123456789012');
        expect(result, isNotNull);
        expect(result, contains('11 dígitos (CPF) ou 14 dígitos (CNPJ)'));
      });

      test('should reject document with 13 digits', () {
        final result = DocumentValidator.validateDocument('1234567890123');
        expect(result, isNotNull);
        expect(result, contains('11 dígitos (CPF) ou 14 dígitos (CNPJ)'));
      });

      test('should reject document with 15 digits', () {
        final result = DocumentValidator.validateDocument('123456789012345');
        expect(result, isNotNull);
        expect(result, contains('11 dígitos (CPF) ou 14 dígitos (CNPJ)'));
      });
    });

    group('Non-Numeric Characters', () {
      test('should reject document with letters', () {
        final result = DocumentValidator.validateDocument('123ABC78909');
        expect(result, isNotNull);
        expect(result, contains('apenas números'));
      });

      test('should reject document with special characters (except formatting)', () {
        final result = DocumentValidator.validateDocument('123#456@789');
        expect(result, isNotNull);
        expect(result, contains('apenas números'));
      });
    });

    group('Formatting Removal', () {
      test('should remove dots and hyphens from CPF', () {
        expect(DocumentValidator.validateDocument('123.456.789-09'), isNull);
      });

      test('should remove dots, slashes and hyphens from CNPJ', () {
        expect(DocumentValidator.validateDocument('11.222.333/0001-81'), isNull);
      });

      test('should handle mixed formatting', () {
        expect(DocumentValidator.validateDocument('123 456 789-09'), isNull);
      });
    });
  });
}
