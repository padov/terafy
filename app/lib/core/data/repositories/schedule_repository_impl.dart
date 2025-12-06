import 'package:common/common.dart';
import 'package:dio/dio.dart';
import 'package:terafy/core/domain/repositories/schedule_repository.dart';
import 'package:terafy/package/http.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required this.httpClient});

  final HttpClient httpClient;

  @override
  Future<TherapistScheduleSettings> fetchSettings({int? therapistId}) async {
    try {
      final response = await httpClient.get(
        '/schedule/settings',
        queryParameters: therapistId != null ? {'therapistId': therapistId.toString()} : null,
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar configurações');
      }

      return TherapistScheduleSettings.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar configurações de agenda');
    }
  }

  @override
  Future<TherapistScheduleSettings> updateSettings(TherapistScheduleSettings settings) async {
    try {
      final response = await httpClient.put('/schedule/settings', data: settings.toJson());

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao atualizar configurações');
      }

      return TherapistScheduleSettings.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao atualizar configurações de agenda');
    }
  }

  @override
  Future<List<Appointment>> fetchAppointments({
    required DateTime start,
    required DateTime end,
    int? therapistId,
  }) async {
    AppLogger.func();
    try {
      final response = await httpClient.get(
        '/schedule/appointments',
        queryParameters: {
          'start': start.toUtc().toIso8601String(),
          'end': end.toUtc().toIso8601String(),
          if (therapistId != null) 'therapistId': therapistId.toString(),
        },
      );

      if (response.data is! List) {
        throw Exception('Resposta inválida ao carregar agendamentos');
      }

      final data = response.data as List;

      return data.map((item) => Appointment.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar agendamentos');
    }
  }

  @override
  Future<Appointment> fetchAppointment(int appointmentId) async {
    AppLogger.func();
    try {
      final response = await httpClient.get('/schedule/appointments/$appointmentId');

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao carregar agendamento');
      }

      return Appointment.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao carregar agendamento');
    }
  }

  @override
  Future<Appointment> createAppointment(Appointment appointment) async {
    AppLogger.func();
    try {
      final response = await httpClient.post('/schedule/appointments', data: appointment.toJson());

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao criar agendamento');
      }

      return Appointment.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao criar agendamento');
    }
  }

  @override
  Future<Appointment> updateAppointment(int appointmentId, Appointment appointment) async {
    AppLogger.func();
    try {
      final response = await httpClient.put('/schedule/appointments/$appointmentId', data: appointment.toJson());

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Resposta inválida ao atualizar agendamento');
      }

      return Appointment.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao atualizar agendamento');
    }
  }

  @override
  Future<void> deleteAppointment(int appointmentId) async {
    AppLogger.func();
    try {
      await httpClient.delete('/schedule/appointments/$appointmentId');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao remover agendamento');
    }
  }

  @override
  Future<List<Map<String, DateTime>>> validateAppointments({
    required List<Map<String, DateTime>> slots,
    int? therapistId,
  }) async {
    AppLogger.func();
    try {
      if (slots.isEmpty) return [];

      final data = {
        'slots': slots
            .map((s) => {'start': s['start']!.toUtc().toIso8601String(), 'end': s['end']!.toUtc().toIso8601String()})
            .toList(),
        if (therapistId != null) 'therapistId': therapistId,
      };

      final response = await httpClient.post('/schedule/appointments/validate', data: data);

      if (response.data is! List) {
        throw Exception('Resposta inválida ao validar agendamentos');
      }

      final conflicts = (response.data as List).map((c) {
        final conflict = Map<String, dynamic>.from(c as Map);
        return {'start': DateTime.parse(conflict['start']), 'end': DateTime.parse(conflict['end'])};
      }).toList();

      return conflicts;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e) ?? 'Erro ao validar agendamentos');
    }
  }

  String? _extractErrorMessage(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } else if (exception.message != null) {
      return exception.message;
    }
    return null;
  }
}
