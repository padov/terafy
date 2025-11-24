class User {
  final int? id;
  final String email;
  final String? passwordHash; // Nullable para não expor em respostas
  final String? phone;
  final String role; // 'therapist', 'patient', 'admin'
  final String?
  accountType; // 'therapist', 'patient' (nullable - será preenchido após completar perfil)
  final int?
  accountId; // FK para therapists ou patients (nullable - será preenchido após completar perfil)
  final String status; // 'active', 'suspended', 'canceled'
  final DateTime? lastLoginAt;
  final bool emailVerified;
  final bool phoneVerified;
  // Campos de TFA (Two-Factor Authentication)
  final bool tfaEnabled;
  final String? tfaSecret; // Secret para TOTP
  final String? tfaMethod; // 'authenticator_app', 'sms', 'email'
  final String?
  tfaBackupCodes; // Códigos de backup (JSON array ou texto separado por vírgula)
  final DateTime? tfaVerifiedAt; // Data em que o TFA foi verificado/ativado
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Helper para parsear campos DateTime que podem vir como String, DateTime ou UndecodedBytes
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    // Para UndecodedBytes ou outros tipos do PostgreSQL
    // Tenta converter para String usando toString() primeiro
    try {
      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) return null;
      return DateTime.parse(stringValue);
    } catch (e) {
      // Se falhar, retorna null silenciosamente
      return null;
    }
  }

  User({
    this.id,
    required this.email,
    this.passwordHash,
    this.phone,
    required this.role,
    this.accountType, // Nullable - será preenchido após completar perfil
    this.accountId, // Nullable - será preenchido após completar perfil
    required this.status,
    this.lastLoginAt,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.tfaEnabled = false,
    this.tfaSecret,
    this.tfaMethod,
    this.tfaBackupCodes,
    this.tfaVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'role': role,
      'account_type': accountType,
      'account_id': accountId,
      'status': status,
      'last_login_at': lastLoginAt?.toIso8601String(),
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'tfa_enabled': tfaEnabled,
      'tfa_method': tfaMethod,
      'tfa_verified_at': tfaVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // password_hash, tfa_secret e tfa_backup_codes nunca são incluídos no JSON por segurança
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String?,
      phone: map['phone'] as String?,
      role: (map['role'] as String?) ?? 'therapist',
      accountType:
          map['account_type'] as String?, // Nullable - não usar fallback
      accountId: map['account_id'] as int?,
      status: (map['status'] as String?) ?? 'active',
      lastLoginAt: _parseDateTime(map['last_login_at']),
      emailVerified: map['email_verified'] as bool? ?? false,
      phoneVerified: map['phone_verified'] as bool? ?? false,
      tfaEnabled: map['tfa_enabled'] as bool? ?? false,
      tfaSecret: map['tfa_secret'] as String?,
      tfaMethod: map['tfa_method'] as String?,
      tfaBackupCodes: map['tfa_backup_codes'] as String?,
      tfaVerifiedAt: _parseDateTime(map['tfa_verified_at']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }
}
