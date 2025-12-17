/// Validates Brazilian CPF and CNPJ documents
class DocumentValidator {
  /// Validates a document (CPF or CNPJ) based on its length
  ///
  /// Returns null if the document is valid or not provided (optional field)
  /// Returns an error message if the document is invalid
  ///
  /// - 11 digits (after removing formatting) = CPF validation
  /// - 14 digits (after removing formatting) = CNPJ validation
  /// - Any other length = invalid
  static String? validateDocument(String? document) {
    // Document is optional, so null or empty is valid
    if (document == null || document.trim().isEmpty) {
      return null;
    }

    // Check if it contains only digits and valid formatting characters (., -, /, space)
    if (!RegExp(r'^[\d.\-/\s]+$').hasMatch(document)) {
      return 'Documento deve conter apenas números';
    }

    final cleanDoc = _removeFormatting(document);

    // After removing formatting, check if we have only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanDoc)) {
      return 'Documento deve conter apenas números';
    }

    // Validate based on length
    if (cleanDoc.length == 11) {
      return _validateCPF(cleanDoc);
    } else if (cleanDoc.length == 14) {
      return _validateCNPJ(cleanDoc);
    } else {
      return 'Documento deve ter 11 dígitos (CPF) ou 14 dígitos (CNPJ)';
    }
  }

  /// Removes all non-numeric characters from a document string
  static String _removeFormatting(String document) {
    return document.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Validates a CPF (11 digits)
  /// Returns null if valid, error message if invalid
  static String? _validateCPF(String cpf) {
    // Check for known invalid CPFs (all same digits)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    // Calculate first check digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;

    if (firstDigit != int.parse(cpf[9])) {
      return 'CPF inválido';
    }

    // Calculate second check digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;

    if (secondDigit != int.parse(cpf[10])) {
      return 'CPF inválido';
    }

    return null; // Valid CPF
  }

  /// Validates a CNPJ (14 digits)
  /// Returns null if valid, error message if invalid
  static String? _validateCNPJ(String cnpj) {
    // Check for known invalid CNPJs (all same digits)
    if (RegExp(r'^(\d)\1{13}$').hasMatch(cnpj)) {
      return 'CNPJ inválido';
    }

    // Calculate first check digit
    final weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int firstDigit = sum % 11;
    firstDigit = firstDigit < 2 ? 0 : 11 - firstDigit;

    if (firstDigit != int.parse(cnpj[12])) {
      return 'CNPJ inválido';
    }

    // Calculate second check digit
    final weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    int secondDigit = sum % 11;
    secondDigit = secondDigit < 2 ? 0 : 11 - secondDigit;

    if (secondDigit != int.parse(cnpj[13])) {
      return 'CNPJ inválido';
    }

    return null; // Valid CNPJ
  }
}
