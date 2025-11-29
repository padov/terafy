import 'package:common/common.dart' as common;
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/therapeutic_plan_repository.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_objective.dart';
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan.dart' as domain;
import 'package:terafy/features/therapeutic_plan/models/therapeutic_plan_mapper.dart';
import 'package:terafy/package/http.dart';

class TherapeuticPlanRepositoryImpl implements TherapeuticPlanRepository {
  TherapeuticPlanRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<List<domain.TherapeuticPlan>> fetchPlans({String? patientId, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (patientId != null) queryParams['patientId'] = patientId;
      if (status != null) queryParams['status'] = status;

      final response = await httpClient.get(
        '/therapeutic-plans',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar planos terapêuticos');
      }

      final data = response.data;
      if (data is! List) {
        throw Exception('Resposta inesperada ao carregar planos terapêuticos');
      }

      return data.cast<Map<String, dynamic>>().map((json) {
        final commonPlan = common.TherapeuticPlan.fromJson(json);
        return mapToDomainPlan(commonPlan);
      }).toList();
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar planos terapêuticos';
      throw Exception(message);
    }
  }

  @override
  Future<domain.TherapeuticPlan> fetchPlanById(String id) async {
    try {
      final response = await httpClient.get('/therapeutic-plans/$id');

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar plano terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar plano terapêutico');
      }

      final commonPlan = common.TherapeuticPlan.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainPlan(commonPlan);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar plano terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<domain.TherapeuticPlan> createPlan({
    required String patientId,
    required String therapistId,
    required String approach,
    String? approachOther,
    String? recommendedFrequency,
    int? sessionDurationMinutes,
    int? estimatedDurationMonths,
    List<String>? mainTechniques,
    String? interventionStrategies,
    String? resourcesToUse,
    String? therapeuticTasks,
    Map<String, dynamic>? monitoringIndicators,
    List<String>? assessmentInstruments,
    String? measurementFrequency,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
  }) async {
    final payload = <String, dynamic>{
      'patientId': int.parse(patientId),
      'therapistId': int.parse(therapistId),
      'approach': approach,
      if (approachOther != null) 'approachOther': approachOther,
      if (recommendedFrequency != null) 'recommendedFrequency': recommendedFrequency,
      if (sessionDurationMinutes != null) 'sessionDurationMinutes': sessionDurationMinutes,
      if (estimatedDurationMonths != null) 'estimatedDurationMonths': estimatedDurationMonths,
      if (mainTechniques != null && mainTechniques.isNotEmpty) 'mainTechniques': mainTechniques,
      if (interventionStrategies != null) 'interventionStrategies': interventionStrategies,
      if (resourcesToUse != null) 'resourcesToUse': resourcesToUse,
      if (therapeuticTasks != null) 'therapeuticTasks': therapeuticTasks,
      if (monitoringIndicators != null) 'monitoringIndicators': monitoringIndicators,
      if (assessmentInstruments != null && assessmentInstruments.isNotEmpty)
        'assessmentInstruments': assessmentInstruments,
      if (measurementFrequency != null) 'measurementFrequency': measurementFrequency,
      if (observations != null) 'observations': observations,
      if (availableResources != null) 'availableResources': availableResources,
      if (supportNetwork != null) 'supportNetwork': supportNetwork,
      if (status != null) 'status': status,
    };

    try {
      final response = await httpClient.post('/therapeutic-plans', data: payload);

      final isSuccess = response.statusCode == 201 || response.statusCode == 200;
      if (!isSuccess || response.data == null) {
        throw Exception('Erro ao criar plano terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao criar plano terapêutico');
      }

      final commonPlan = common.TherapeuticPlan.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainPlan(commonPlan);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar plano terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<domain.TherapeuticPlan> updatePlan({
    required String id,
    String? patientId,
    String? therapistId,
    String? approach,
    String? approachOther,
    String? recommendedFrequency,
    int? sessionDurationMinutes,
    int? estimatedDurationMonths,
    List<String>? mainTechniques,
    String? interventionStrategies,
    String? resourcesToUse,
    String? therapeuticTasks,
    Map<String, dynamic>? monitoringIndicators,
    List<String>? assessmentInstruments,
    String? measurementFrequency,
    String? observations,
    String? availableResources,
    String? supportNetwork,
    String? status,
    DateTime? reviewedAt,
  }) async {
    final payload = <String, dynamic>{};
    if (patientId != null) payload['patientId'] = int.parse(patientId);
    if (therapistId != null) payload['therapistId'] = int.parse(therapistId);
    if (approach != null) payload['approach'] = approach;
    if (approachOther != null) payload['approachOther'] = approachOther;
    if (recommendedFrequency != null) payload['recommendedFrequency'] = recommendedFrequency;
    if (sessionDurationMinutes != null) payload['sessionDurationMinutes'] = sessionDurationMinutes;
    if (estimatedDurationMonths != null) payload['estimatedDurationMonths'] = estimatedDurationMonths;
    if (mainTechniques != null && mainTechniques.isNotEmpty) payload['mainTechniques'] = mainTechniques;
    if (interventionStrategies != null) payload['interventionStrategies'] = interventionStrategies;
    if (resourcesToUse != null) payload['resourcesToUse'] = resourcesToUse;
    if (therapeuticTasks != null) payload['therapeuticTasks'] = therapeuticTasks;
    if (monitoringIndicators != null) payload['monitoringIndicators'] = monitoringIndicators;
    if (assessmentInstruments != null && assessmentInstruments.isNotEmpty)
      payload['assessmentInstruments'] = assessmentInstruments;
    if (measurementFrequency != null) payload['measurementFrequency'] = measurementFrequency;
    if (observations != null) payload['observations'] = observations;
    if (availableResources != null) payload['availableResources'] = availableResources;
    if (supportNetwork != null) payload['supportNetwork'] = supportNetwork;
    if (status != null) payload['status'] = status;
    if (reviewedAt != null) payload['reviewedAt'] = reviewedAt.toIso8601String();

    try {
      final response = await httpClient.put('/therapeutic-plans/$id', data: payload);

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao atualizar plano terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao atualizar plano terapêutico');
      }

      final commonPlan = common.TherapeuticPlan.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainPlan(commonPlan);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao atualizar plano terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<void> deletePlan(String id) async {
    try {
      final response = await httpClient.delete('/therapeutic-plans/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao remover plano terapêutico');
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao remover plano terapêutico';
      throw Exception(message);
    }
  }

  // ============ OBJECTIVES ============

  @override
  Future<List<TherapeuticObjective>> fetchObjectives({
    String? planId,
    String? patientId,
    String? status,
    String? priority,
    String? deadlineType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (planId != null) queryParams['planId'] = planId;
      if (patientId != null) queryParams['patientId'] = patientId;
      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;
      if (deadlineType != null) queryParams['deadlineType'] = deadlineType;

      final response = await httpClient.get(
        '/therapeutic-plans/objectives',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar objetivos terapêuticos');
      }

      final data = response.data;
      if (data is! List) {
        throw Exception('Resposta inesperada ao carregar objetivos terapêuticos');
      }

      return data.cast<Map<String, dynamic>>().map((json) {
        final commonObjective = common.TherapeuticObjective.fromJson(json);
        return mapToDomainObjective(commonObjective);
      }).toList();
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar objetivos terapêuticos';
      throw Exception(message);
    }
  }

  @override
  Future<TherapeuticObjective> fetchObjectiveById(String id) async {
    try {
      final response = await httpClient.get('/therapeutic-plans/objectives/$id');

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao carregar objetivo terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao carregar objetivo terapêutico');
      }

      final commonObjective = common.TherapeuticObjective.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainObjective(commonObjective);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao carregar objetivo terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<TherapeuticObjective> createObjective({
    required String therapeuticPlanId,
    required String patientId,
    required String therapistId,
    required String description,
    required String specificAspect,
    required String measurableCriteria,
    String? achievableConditions,
    String? relevantJustification,
    String? timeBoundDeadline,
    String? deadlineType,
    String? priority,
    String? status,
    int? progressPercentage,
    Map<String, dynamic>? progressIndicators,
    String? successMetric,
    DateTime? targetDate,
    String? notes,
    int? displayOrder,
  }) async {
    final payload = <String, dynamic>{
      'therapeuticPlanId': int.parse(therapeuticPlanId),
      'patientId': int.parse(patientId),
      'therapistId': int.parse(therapistId),
      'description': description,
      'specificAspect': specificAspect,
      'measurableCriteria': measurableCriteria,
      if (achievableConditions != null) 'achievableConditions': achievableConditions,
      if (relevantJustification != null) 'relevantJustification': relevantJustification,
      if (timeBoundDeadline != null) 'timeBoundDeadline': timeBoundDeadline,
      if (deadlineType != null) 'deadlineType': deadlineType,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (progressPercentage != null) 'progressPercentage': progressPercentage,
      if (progressIndicators != null) 'progressIndicators': progressIndicators,
      if (successMetric != null) 'successMetric': successMetric,
      if (targetDate != null) 'targetDate': targetDate.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };

    try {
      final response = await httpClient.post('/therapeutic-plans/objectives', data: payload);

      final isSuccess = response.statusCode == 201 || response.statusCode == 200;
      if (!isSuccess || response.data == null) {
        throw Exception('Erro ao criar objetivo terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao criar objetivo terapêutico');
      }

      final commonObjective = common.TherapeuticObjective.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainObjective(commonObjective);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao criar objetivo terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<TherapeuticObjective> updateObjective({
    required String id,
    String? description,
    String? specificAspect,
    String? measurableCriteria,
    String? achievableConditions,
    String? relevantJustification,
    String? timeBoundDeadline,
    String? deadlineType,
    String? priority,
    String? status,
    int? progressPercentage,
    Map<String, dynamic>? progressIndicators,
    String? successMetric,
    DateTime? targetDate,
    String? abandonedReason,
    String? notes,
    int? displayOrder,
  }) async {
    final payload = <String, dynamic>{};
    if (description != null) payload['description'] = description;
    if (specificAspect != null) payload['specificAspect'] = specificAspect;
    if (measurableCriteria != null) payload['measurableCriteria'] = measurableCriteria;
    if (achievableConditions != null) payload['achievableConditions'] = achievableConditions;
    if (relevantJustification != null) payload['relevantJustification'] = relevantJustification;
    if (timeBoundDeadline != null) payload['timeBoundDeadline'] = timeBoundDeadline;
    if (deadlineType != null) payload['deadlineType'] = deadlineType;
    if (priority != null) payload['priority'] = priority;
    if (status != null) payload['status'] = status;
    if (progressPercentage != null) payload['progressPercentage'] = progressPercentage;
    if (progressIndicators != null) payload['progressIndicators'] = progressIndicators;
    if (successMetric != null) payload['successMetric'] = successMetric;
    if (targetDate != null) payload['targetDate'] = targetDate.toIso8601String().split('T')[0];
    if (abandonedReason != null) payload['abandonedReason'] = abandonedReason;
    if (notes != null) payload['notes'] = notes;
    if (displayOrder != null) payload['displayOrder'] = displayOrder;

    try {
      final response = await httpClient.put('/therapeutic-plans/objectives/$id', data: payload);

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Erro ao atualizar objetivo terapêutico');
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inesperada ao atualizar objetivo terapêutico');
      }

      final commonObjective = common.TherapeuticObjective.fromJson(response.data as Map<String, dynamic>);
      return mapToDomainObjective(commonObjective);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao atualizar objetivo terapêutico';
      throw Exception(message);
    }
  }

  @override
  Future<void> deleteObjective(String id) async {
    try {
      final response = await httpClient.delete('/therapeutic-plans/objectives/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro ao remover objetivo terapêutico');
      }
    } on DioException catch (e) {
      final message = _extractErrorMessage(e) ?? 'Erro ao remover objetivo terapêutico';
      throw Exception(message);
    }
  }

  String? _extractErrorMessage(DioException exception) {
    if (exception.response?.data is Map<String, dynamic>) {
      final map = exception.response!.data as Map<String, dynamic>;
      final error = map['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (exception.message != null) {
      return exception.message;
    }
    return null;
  }
}
