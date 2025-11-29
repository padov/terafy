import 'package:common/common.dart';
import 'package:server/features/therapeutic_plan/therapeutic_plan.repository.dart';

class TherapeuticPlanException implements Exception {
  TherapeuticPlanException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class TherapeuticPlanController {
  TherapeuticPlanController(this._repository);

  final TherapeuticPlanRepository _repository;

  // ============ THERAPEUTIC PLAN METHODS ============

  Future<TherapeuticPlan> createPlan({
    required TherapeuticPlan plan,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (plan.patientId <= 0) {
        throw TherapeuticPlanException('ID do paciente inválido', 400);
      }

      if (plan.therapistId <= 0) {
        throw TherapeuticPlanException('ID do terapeuta inválido', 400);
      }

      if (plan.approach.isEmpty) {
        throw TherapeuticPlanException('Abordagem terapêutica é obrigatória', 400);
      }

      if (plan.approach == 'other' && (plan.approachOther == null || plan.approachOther!.isEmpty)) {
        throw TherapeuticPlanException('Quando a abordagem é "other", o campo approachOther é obrigatório', 400);
      }

      // Validação de campos opcionais mas importantes
      if (plan.sessionDurationMinutes != null && plan.sessionDurationMinutes! <= 0) {
        throw TherapeuticPlanException('Duração da sessão deve ser maior que zero', 400);
      }

      if (plan.estimatedDurationMonths != null && plan.estimatedDurationMonths! <= 0) {
        throw TherapeuticPlanException('Duração estimada em meses deve ser maior que zero', 400);
      }

      // Validação: apenas um plano ativo por paciente
      if (plan.status == 'active') {
        final existingActivePlans = await _repository.listPlans(
          patientId: plan.patientId,
          status: 'active',
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? plan.therapistId,
          bypassRLS: userRole == 'admin',
        );

        if (existingActivePlans.isNotEmpty) {
          // Se há um plano ativo diferente, não pode criar outro
          final hasOtherActivePlan = existingActivePlans.any((p) => p.id != plan.id);
          if (hasOtherActivePlan) {
            throw TherapeuticPlanException(
              'Já existe um plano terapêutico ativo para este paciente. '
              'Finalize ou arquive o plano existente antes de criar um novo.',
              409,
            );
          }
        }
      }

      final created = await _repository.createPlan(
        plan: plan,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return created;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao criar plano terapêutico: ${e.toString()}', 500);
    }
  }

  Future<TherapeuticPlan> getPlan({required int planId, required int userId, String? userRole, int? accountId}) async {
    AppLogger.func();
    try {
      final plan = await _repository.getPlanById(
        planId: planId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (plan == null) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }

      return plan;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao buscar plano terapêutico: ${e.toString()}', 500);
    }
  }

  Future<List<TherapeuticPlan>> listPlans({
    int? patientId,
    int? therapistId,
    String? status,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final plans = await _repository.listPlans(
        patientId: patientId,
        therapistId: therapistId,
        status: status,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return plans;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao listar planos terapêuticos: ${e.toString()}', 500);
    }
  }

  Future<TherapeuticPlan> updatePlan({
    required int planId,
    required TherapeuticPlan plan,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (plan.approach.isEmpty) {
        throw TherapeuticPlanException('Abordagem terapêutica é obrigatória', 400);
      }

      if (plan.approach == 'other' && (plan.approachOther == null || plan.approachOther!.isEmpty)) {
        throw TherapeuticPlanException('Quando a abordagem é "other", o campo approachOther é obrigatório', 400);
      }

      if (plan.sessionDurationMinutes != null && plan.sessionDurationMinutes! <= 0) {
        throw TherapeuticPlanException('Duração da sessão deve ser maior que zero', 400);
      }

      if (plan.estimatedDurationMonths != null && plan.estimatedDurationMonths! <= 0) {
        throw TherapeuticPlanException('Duração estimada em meses deve ser maior que zero', 400);
      }

      // Buscar plano atual
      final currentPlan = await _repository.getPlanById(
        planId: planId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (currentPlan == null) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }

      // Validação: apenas um plano ativo por paciente
      // Se está mudando para ativo, verificar se já existe outro ativo
      if (plan.status == 'active' && currentPlan.status != 'active') {
        final existingActivePlans = await _repository.listPlans(
          patientId: plan.patientId,
          status: 'active',
          userId: userId,
          userRole: userRole,
          accountId: accountId ?? plan.therapistId,
          bypassRLS: userRole == 'admin',
        );

        final hasOtherActivePlan = existingActivePlans.any((p) => p.id != planId);
        if (hasOtherActivePlan) {
          throw TherapeuticPlanException(
            'Já existe um plano terapêutico ativo para este paciente. '
            'Finalize ou arquive o plano existente antes de ativar este.',
            409,
          );
        }
      }

      // Se está mudando de status para reviewing, atualizar reviewed_at
      TherapeuticPlan planToUpdate = plan;
      if (plan.status == 'reviewing' && currentPlan.status != 'reviewing') {
        planToUpdate = plan.copyWith(reviewedAt: DateTime.now().toUtc());
      }

      final updated = await _repository.updatePlan(
        planId: planId,
        plan: planToUpdate,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (updated == null) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }

      return updated;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao atualizar plano terapêutico: ${e.toString()}', 500);
    }
  }

  Future<void> deletePlan({required int planId, required int userId, String? userRole, int? accountId}) async {
    AppLogger.func();
    try {
      // Verificar se o plano existe antes de deletar
      final plan = await _repository.getPlanById(
        planId: planId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (plan == null) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }

      // Verificar se o plano tem objetivos vinculados
      final objectives = await _repository.listObjectives(
        planId: planId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (objectives.isNotEmpty) {
        throw TherapeuticPlanException(
          'Não é possível excluir um plano que possui objetivos terapêuticos vinculados. '
          'Remova os objetivos primeiro ou arquive o plano.',
          409,
        );
      }

      final deleted = await _repository.deletePlan(
        planId: planId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (!deleted) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao remover plano terapêutico: ${e.toString()}', 500);
    }
  }

  // ============ THERAPEUTIC OBJECTIVE METHODS ============

  Future<TherapeuticObjective> createObjective({
    required TherapeuticObjective objective,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (objective.therapeuticPlanId <= 0) {
        throw TherapeuticPlanException('ID do plano terapêutico inválido', 400);
      }

      if (objective.patientId <= 0) {
        throw TherapeuticPlanException('ID do paciente inválido', 400);
      }

      if (objective.therapistId <= 0) {
        throw TherapeuticPlanException('ID do terapeuta inválido', 400);
      }

      if (objective.description.trim().isEmpty) {
        throw TherapeuticPlanException('Descrição do objetivo é obrigatória', 400);
      }

      if (objective.specificAspect.trim().isEmpty) {
        throw TherapeuticPlanException('Aspecto específico (SMART) é obrigatório', 400);
      }

      if (objective.measurableCriteria.trim().isEmpty) {
        throw TherapeuticPlanException('Critério mensurável (SMART) é obrigatório', 400);
      }

      if (objective.progressPercentage < 0 || objective.progressPercentage > 100) {
        throw TherapeuticPlanException('Progresso deve estar entre 0 e 100', 400);
      }

      // Verificar se o plano existe
      final plan = await _repository.getPlanById(
        planId: objective.therapeuticPlanId,
        userId: userId,
        userRole: userRole,
        accountId: accountId ?? objective.therapistId,
        bypassRLS: userRole == 'admin',
      );

      if (plan == null) {
        throw TherapeuticPlanException('Plano terapêutico não encontrado', 404);
      }

      // Verificar se o plano não está arquivado
      if (plan.status == 'archived') {
        throw TherapeuticPlanException('Não é possível adicionar objetivos a um plano arquivado', 409);
      }

      // Se não foi especificado display_order, calcular o próximo
      TherapeuticObjective objectiveToCreate = objective;
      if (objective.displayOrder == 0) {
        final existingObjectives = await _repository.listObjectives(
          planId: objective.therapeuticPlanId,
          userId: userId,
          userRole: userRole,
          accountId: accountId,
          bypassRLS: userRole == 'admin',
        );
        final nextOrder = existingObjectives.isEmpty
            ? 1
            : existingObjectives.map((o) => o.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
        objectiveToCreate = objective.copyWith(displayOrder: nextOrder);
      }

      final created = await _repository.createObjective(
        objective: objectiveToCreate,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return created;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao criar objetivo terapêutico: ${e.toString()}', 500);
    }
  }

  Future<TherapeuticObjective> getObjective({
    required int objectiveId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final objective = await _repository.getObjectiveById(
        objectiveId: objectiveId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (objective == null) {
        throw TherapeuticPlanException('Objetivo terapêutico não encontrado', 404);
      }

      return objective;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao buscar objetivo terapêutico: ${e.toString()}', 500);
    }
  }

  Future<List<TherapeuticObjective>> listObjectives({
    int? planId,
    int? patientId,
    int? therapistId,
    String? status,
    String? priority,
    String? deadlineType,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final objectives = await _repository.listObjectives(
        planId: planId,
        patientId: patientId,
        therapistId: therapistId,
        status: status,
        priority: priority,
        deadlineType: deadlineType,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      return objectives;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao listar objetivos terapêuticos: ${e.toString()}', 500);
    }
  }

  Future<TherapeuticObjective> updateObjective({
    required int objectiveId,
    required TherapeuticObjective objective,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      // Validações básicas
      if (objective.description.trim().isEmpty) {
        throw TherapeuticPlanException('Descrição do objetivo é obrigatória', 400);
      }

      if (objective.specificAspect.trim().isEmpty) {
        throw TherapeuticPlanException('Aspecto específico (SMART) é obrigatório', 400);
      }

      if (objective.measurableCriteria.trim().isEmpty) {
        throw TherapeuticPlanException('Critério mensurável (SMART) é obrigatório', 400);
      }

      if (objective.progressPercentage < 0 || objective.progressPercentage > 100) {
        throw TherapeuticPlanException('Progresso deve estar entre 0 e 100', 400);
      }

      // Buscar objetivo atual
      final currentObjective = await _repository.getObjectiveById(
        objectiveId: objectiveId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (currentObjective == null) {
        throw TherapeuticPlanException('Objetivo terapêutico não encontrado', 404);
      }

      // Se está marcando como completo, garantir progresso 100%
      TherapeuticObjective objectiveToUpdate = objective;
      if (objective.status == 'completed' && currentObjective.status != 'completed') {
        objectiveToUpdate = objective.copyWith(progressPercentage: 100, completedAt: DateTime.now().toUtc());
      }

      // Se está marcando como abandonado, garantir que tem razão
      if (objective.status == 'abandoned' &&
          currentObjective.status != 'abandoned' &&
          (objective.abandonedReason == null || objective.abandonedReason!.trim().isEmpty)) {
        throw TherapeuticPlanException('Razão do abandono é obrigatória ao abandonar um objetivo', 400);
      }

      final updated = await _repository.updateObjective(
        objectiveId: objectiveId,
        objective: objectiveToUpdate,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (updated == null) {
        throw TherapeuticPlanException('Objetivo terapêutico não encontrado', 404);
      }

      return updated;
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao atualizar objetivo terapêutico: ${e.toString()}', 500);
    }
  }

  Future<void> deleteObjective({
    required int objectiveId,
    required int userId,
    String? userRole,
    int? accountId,
  }) async {
    AppLogger.func();
    try {
      final deleted = await _repository.deleteObjective(
        objectiveId: objectiveId,
        userId: userId,
        userRole: userRole,
        accountId: accountId,
        bypassRLS: userRole == 'admin',
      );

      if (!deleted) {
        throw TherapeuticPlanException('Objetivo terapêutico não encontrado', 404);
      }
    } catch (e, stack) {
      AppLogger.error(e, stack);
      if (e is TherapeuticPlanException) rethrow;
      throw TherapeuticPlanException('Erro ao remover objetivo terapêutico: ${e.toString()}', 500);
    }
  }
}
