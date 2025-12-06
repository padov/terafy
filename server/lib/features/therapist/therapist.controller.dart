import 'package:common/common.dart';
import 'package:server/features/user/user.repository.dart';
import 'therapist.repository.dart';

/// Resultado de uma operação de criação de terapeuta
class CreateTherapistResult {
  final Therapist therapist;

  CreateTherapistResult({required this.therapist});
}

/// Resultado de busca de terapeuta com informações do plano
class TherapistWithPlanResult {
  final Map<String, dynamic> therapistData;

  TherapistWithPlanResult({required this.therapistData});
}

/// Exceção customizada para erros relacionados a terapeutas
class TherapistException implements Exception {
  final String message;
  final int statusCode;

  TherapistException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Controller responsável pela lógica de negócio relacionada a terapeutas
class TherapistController {
  final TherapistRepository _repository;
  final UserRepository _userRepository;

  TherapistController(this._repository, this._userRepository);

  /// Lista todos os terapeutas
  ///
  /// [userId] - ID do usuário para contexto RLS
  /// [userRole] - Role do usuário para contexto RLS
  /// [bypassRLS] - Se true, bypass RLS (para admin)
  ///
  /// Retorna [List<Therapist>] em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<List<Therapist>> getAllTherapists({int? userId, String? userRole, bool bypassRLS = false}) async {
    AppLogger.func();
    try {
      return await _repository.getAllTherapists(userId: userId, userRole: userRole, bypassRLS: bypassRLS);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw TherapistException('Erro ao buscar terapeutas: ${e.toString()}', 500);
    }
  }

  /// Busca um terapeuta por ID
  ///
  /// [id] - ID do terapeuta
  /// [userId] - ID do usuário para contexto RLS
  /// [userRole] - Role do usuário para contexto RLS
  /// [accountId] - ID da conta vinculada para contexto RLS
  /// [bypassRLS] - Se true, bypass RLS (para admin)
  ///
  /// Retorna [Therapist] em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<Therapist> getTherapistById(
    int id, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    final therapist = await _repository.getTherapistById(
      id,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );
    if (therapist == null) {
      throw TherapistException('Terapeuta não encontrado', 404);
    }
    return therapist;
  }

  /// Busca o terapeuta do usuário autenticado com informações do plano
  ///
  /// Retorna [TherapistWithPlanResult] em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<TherapistWithPlanResult> getTherapistByUserId(int userId) async {
    AppLogger.func();
    final therapistData = await _repository.getTherapistByUserIdWithPlan(userId);
    if (therapistData == null) {
      throw TherapistException('Terapeuta não encontrado', 404);
    }
    return TherapistWithPlanResult(therapistData: therapistData);
  }

  /// Cria um novo terapeuta e vincula ao usuário
  ///
  /// [therapist] - Dados do terapeuta a ser criado
  /// [userId] - ID do usuário que será vinculado
  /// [userRole] - Role do usuário para contexto RLS
  /// [planId] - ID do plano (opcional)
  ///
  /// Retorna [CreateTherapistResult] em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<CreateTherapistResult> createTherapist({
    required Therapist therapist,
    required int userId,
    String? userRole,
    int? planId,
  }) async {
    AppLogger.func();
    // Verifica se o usuário já tem um therapist vinculado
    final existingTherapistData = await _repository.getTherapistByUserIdWithPlan(userId);
    if (existingTherapistData != null) {
      throw TherapistException('Usuário já possui um perfil de terapeuta vinculado', 400);
    }

    // Cria o therapist (com contexto RLS para policy de criação)
    final createdTherapist = await _repository.createTherapist(therapist, userId: userId, userRole: userRole);

    // Cria a subscription do plano se planId foi fornecido
    if (planId != null) {
      try {
        await _repository.createPlanSubscription(therapistId: createdTherapist.id!, planId: planId);
        AppLogger.debug('Subscription do plano $planId criada com sucesso');
      } catch (e) {
        // Log do erro mas não falha a criação do terapeuta
        AppLogger.warning('Aviso: Erro ao criar subscription do plano $planId: $e');
      }
    }

    // Atualiza o usuário com accountType e accountId
    try {
      await _userRepository.updateUserAccount(
        userId: userId,
        accountType: 'therapist',
        accountId: createdTherapist.id!,
      );
      AppLogger.debug('Usuário atualizado com accountId: ${createdTherapist.id}');
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw TherapistException('Erro ao atualizar usuário: ${e.toString()}', 500);
    }

    // Atualiza o therapist com user_id
    try {
      final updatedTherapist = await _repository.updateTherapistUserId(createdTherapist.id!, userId);
      AppLogger.debug('Therapist atualizado com userId: $userId');

      return CreateTherapistResult(therapist: updatedTherapist);
    } catch (e, stack) {
      AppLogger.error(e, stack);
      throw TherapistException('Erro ao atualizar therapist: ${e.toString()}', 500);
    }
  }

  /// Atualiza um terapeuta existente
  ///
  /// [id] - ID do terapeuta a ser atualizado
  /// [therapist] - Dados atualizados do terapeuta
  /// [userId] - ID do usuário para contexto RLS
  /// [userRole] - Role do usuário para contexto RLS
  /// [accountId] - ID da conta vinculada para contexto RLS
  /// [bypassRLS] - Se true, bypass RLS (para admin)
  ///
  /// Retorna [Therapist] em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<Therapist> updateTherapist(
    int id,
    Therapist therapist, {
    int? userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    AppLogger.func();
    final updatedTherapist = await _repository.updateTherapist(
      id,
      therapist,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );
    if (updatedTherapist == null) {
      throw TherapistException('Terapeuta não encontrado', 404);
    }
    return updatedTherapist;
  }

  /// Deleta um terapeuta
  ///
  /// [id] - ID do terapeuta a ser deletado
  /// [userId] - ID do usuário para contexto RLS
  /// [userRole] - Role do usuário para contexto RLS
  /// [accountId] - ID da conta vinculada para contexto RLS
  /// [bypassRLS] - Se true, bypass RLS (para admin)
  ///
  /// Retorna `true` em caso de sucesso
  /// Lança [TherapistException] em caso de erro
  Future<bool> deleteTherapist(int id, {int? userId, String? userRole, int? accountId, bool bypassRLS = false}) async {
    AppLogger.func();
    final deleted = await _repository.deleteTherapist(
      id,
      userId: userId,
      userRole: userRole,
      accountId: accountId,
      bypassRLS: bypassRLS,
    );
    if (!deleted) {
      throw TherapistException('Terapeuta não encontrado', 404);
    }
    return true;
  }
}
