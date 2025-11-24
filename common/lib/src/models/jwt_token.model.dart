/// Model que representa os claims de um token JWT
///
/// Este model encapsula todos os campos do token JWT, fornecendo
/// acesso tipado e métodos auxiliares para trabalhar com os dados.
class JwtToken {
  /// Subject (User ID) - ID do usuário no sistema
  final int userId;

  /// Email do usuário autenticado
  final String email;

  /// Role do usuário ('therapist', 'patient', 'admin')
  final String role;

  /// Tipo de conta vinculada ('therapist' ou 'patient')
  /// Null se o usuário ainda não completou o perfil
  final String? accountType;

  /// ID da conta vinculada (therapist_id ou patient_id)
  /// Null se o usuário ainda não completou o perfil
  final int? accountId;

  /// Issued At - Timestamp de quando o token foi emitido (Unix timestamp em segundos)
  final int issuedAt;

  /// Expiration - Timestamp de quando o token expira (Unix timestamp em segundos)
  final int expiration;

  JwtToken({
    required this.userId,
    required this.email,
    required this.role,
    this.accountType,
    this.accountId,
    required this.issuedAt,
    required this.expiration,
  });

  /// Cria um JwtToken a partir de um Map (claims decodificados do token)
  ///
  /// [map] - Map com os claims do token JWT
  ///
  /// Exemplo:
  /// ```dart
  /// final claims = JwtService.validateToken(token);
  /// if (claims != null) {
  ///   final jwtToken = JwtToken.fromMap(claims);
  /// }
  /// ```
  factory JwtToken.fromMap(Map<String, dynamic> map) {
    // Extrai userId do campo 'sub' (Subject)
    final sub = map['sub'];
    final userId = sub is int
        ? sub
        : int.tryParse(sub.toString()) ??
              (throw ArgumentError('Invalid sub (userId) in token claims'));

    // Extrai email
    final email =
        map['email'] as String? ??
        (throw ArgumentError('Email is required in token claims'));

    // Extrai role
    final role =
        map['role'] as String? ??
        (throw ArgumentError('Role is required in token claims'));

    // Extrai accountType (nullable)
    final accountType = map['account_type'] as String?;
    if (accountType != null && accountType.isEmpty) {
      // Se for string vazia, trata como null
      // ignore: prefer_initializing_formals
    }

    // Extrai accountId (nullable)
    final accountIdValue = map['account_id'];
    final accountId = accountIdValue is int
        ? accountIdValue
        : accountIdValue is String
        ? int.tryParse(accountIdValue)
        : accountIdValue != null
        ? int.tryParse(accountIdValue.toString())
        : null;

    // Extrai issuedAt (iat)
    final iat = map['iat'];
    final issuedAt = iat is int
        ? iat
        : int.tryParse(iat.toString()) ??
              (throw ArgumentError('Invalid iat (issuedAt) in token claims'));

    // Extrai expiration (exp)
    final exp = map['exp'];
    final expiration = exp is int
        ? exp
        : int.tryParse(exp.toString()) ??
              (throw ArgumentError('Invalid exp (expiration) in token claims'));

    return JwtToken(
      userId: userId,
      email: email,
      role: role,
      accountType: accountType?.isEmpty == true ? null : accountType,
      accountId: accountId,
      issuedAt: issuedAt,
      expiration: expiration,
    );
  }

  /// Converte o token para um Map (útil para serialização)
  Map<String, dynamic> toMap() {
    return {
      'sub': userId.toString(),
      'email': email,
      'role': role,
      'account_type': accountType,
      'account_id': accountId,
      'iat': issuedAt,
      'exp': expiration,
    };
  }

  /// Converte o token para JSON (alias para toMap)
  Map<String, dynamic> toJson() => toMap();

  /// Retorna o userId como String (formato do campo 'sub' no token)
  String get userIdString => userId.toString();

  /// Retorna a data de emissão do token como DateTime
  DateTime get issuedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(issuedAt * 1000);

  /// Retorna a data de expiração do token como DateTime
  DateTime get expirationDateTime =>
      DateTime.fromMillisecondsSinceEpoch(expiration * 1000);

  /// Verifica se o token está expirado
  bool get isExpired => DateTime.now().isAfter(expirationDateTime);

  /// Retorna o tempo restante até a expiração
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (isExpired) {
      return Duration.zero;
    }
    return expirationDateTime.difference(now);
  }

  /// Verifica se o usuário tem uma conta vinculada
  bool get hasAccount => accountType != null && accountId != null;

  /// Verifica se o usuário é um terapeuta
  bool get isTherapist => role == 'therapist';

  /// Verifica se o usuário é um paciente
  bool get isPatient => role == 'patient';

  /// Verifica se o usuário é um admin
  bool get isAdmin => role == 'admin';

  /// Verifica se o usuário tem perfil de terapeuta vinculado
  bool get hasTherapistAccount => hasAccount && accountType == 'therapist';

  /// Verifica se o usuário tem perfil de paciente vinculado
  bool get hasPatientAccount => hasAccount && accountType == 'patient';

  /// Retorna o therapist_id se o usuário tem conta de terapeuta
  int? get therapistId => hasTherapistAccount ? accountId : null;

  /// Retorna o patient_id se o usuário tem conta de paciente
  int? get patientId => hasPatientAccount ? accountId : null;

  @override
  String toString() {
    return 'JwtToken('
        'userId: $userId, '
        'email: $email, '
        'role: $role, '
        'accountType: $accountType, '
        'accountId: $accountId, '
        'issuedAt: ${issuedAtDateTime.toIso8601String()}, '
        'expiration: ${expirationDateTime.toIso8601String()}, '
        'isExpired: $isExpired'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JwtToken &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          role == other.role &&
          accountType == other.accountType &&
          accountId == other.accountId &&
          issuedAt == other.issuedAt &&
          expiration == other.expiration;

  @override
  int get hashCode =>
      userId.hashCode ^
      email.hashCode ^
      role.hashCode ^
      (accountType?.hashCode ?? 0) ^
      (accountId?.hashCode ?? 0) ^
      issuedAt.hashCode ^
      expiration.hashCode;
}

