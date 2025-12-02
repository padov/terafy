import 'package:common/common.dart';
import 'package:server/features/schedule/schedule.repository.dart';
import 'package:server/core/database/db_connection.dart';
import 'package:postgres/postgres.dart';

// Mock do DBConnection para testes
class MockDBConnection extends DBConnection {
  @override
  Future<Connection> getConnection() async {
    throw UnimplementedError('Use TestScheduleRepository para testes com dados mockados');
  }
}

// Classe auxiliar para testes que simula o comportamento do ScheduleRepository
class TestScheduleRepository extends ScheduleRepository {
  final List<Appointment> _appointments = [];
  int _lastId = 0;
  int? _currentUserId;
  bool _bypassRLS = false;

  TestScheduleRepository() : super(MockDBConnection());

  void _setRLSContext({int? userId, String? userRole, int? accountId, bool bypassRLS = false}) {
    _currentUserId = userId;
    _bypassRLS = bypassRLS;
  }

  List<Appointment> _filterByRLS(List<Appointment> appointments) {
    if (_bypassRLS) {
      return appointments;
    }
    if (_currentUserId == null) {
      return [];
    }
    return appointments; // Simplificado para testes
  }

  bool _hasTimeConflict(Appointment newAppointment) {
    return _appointments.any((existing) {
      if (existing.therapistId != newAppointment.therapistId) {
        return false; // Diferentes therapists, sem conflito
      }
      // Verifica sobreposição de horários
      return (newAppointment.startTime.isBefore(existing.endTime) &&
          newAppointment.endTime.isAfter(existing.startTime));
    });
  }

  @override
  Future<Appointment> createAppointment({
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    // Valida conflito de horário
    if (_hasTimeConflict(appointment)) {
      throw Exception('Conflito de horário: já existe um appointment neste período');
    }

    final now = DateTime.now();
    final newAppointment = Appointment(
      id: ++_lastId,
      therapistId: appointment.therapistId,
      patientId: appointment.patientId,
      patientName: appointment.patientName,
      type: appointment.type,
      status: appointment.status,
      title: appointment.title,
      description: appointment.description,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      recurrenceRule: appointment.recurrenceRule,
      recurrenceEnd: appointment.recurrenceEnd,
      recurrenceExceptions: appointment.recurrenceExceptions,
      location: appointment.location,
      onlineLink: appointment.onlineLink,
      color: appointment.color,
      reminders: appointment.reminders,
      reminderSentAt: appointment.reminderSentAt,
      patientConfirmedAt: appointment.patientConfirmedAt,
      patientArrivalAt: appointment.patientArrivalAt,
      waitingRoomStatus: appointment.waitingRoomStatus,
      cancellationReason: appointment.cancellationReason,
      notes: appointment.notes,
      parentAppointmentId: appointment.parentAppointmentId,
      sessionId: appointment.sessionId,
      createdAt: now,
      updatedAt: now,
    );
    _appointments.add(newAppointment);
    return newAppointment;
  }

  @override
  Future<Appointment?> getAppointmentById({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);
    try {
      final appointment = _appointments.firstWhere((a) => a.id == appointmentId);
      final filtered = _filterByRLS([appointment]);
      return filtered.isEmpty ? null : filtered.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Appointment>> listAppointments({
    required int therapistId,
    required DateTime start,
    required DateTime end,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    var filtered = _appointments.where((a) => a.therapistId == therapistId).toList();
    filtered = filtered.where((a) {
      return (a.startTime.isBefore(end) && a.endTime.isAfter(start));
    }).toList();

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return _filterByRLS(filtered);
  }

  @override
  Future<Appointment> updateAppointment({
    required int appointmentId,
    required Appointment appointment,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) {
      throw Exception('Appointment não encontrado');
    }

    final existing = _appointments[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      throw Exception('Appointment não encontrado ou acesso negado');
    }

    // Valida conflito de horário (excluindo o próprio appointment)
    final tempAppointment = appointment.copyWith(id: null);
    final hasConflict = _appointments.any((a) {
      if (a.id == appointmentId) return false; // Ignora o próprio appointment
      if (a.therapistId != tempAppointment.therapistId) return false;
      return (tempAppointment.startTime.isBefore(a.endTime) && tempAppointment.endTime.isAfter(a.startTime));
    });

    if (hasConflict) {
      throw Exception('Conflito de horário: já existe um appointment neste período');
    }

    final updated = appointment.copyWith(
      id: existing.id,
      therapistId: existing.therapistId, // Não pode mudar
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _appointments[index] = updated;
    return updated;
  }

  @override
  Future<bool> deleteAppointment({
    required int appointmentId,
    required int userId,
    String? userRole,
    int? accountId,
    bool bypassRLS = false,
  }) async {
    _setRLSContext(userId: userId, userRole: userRole, accountId: accountId, bypassRLS: bypassRLS);

    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) {
      return false;
    }

    final existing = _appointments[index];
    final filtered = _filterByRLS([existing]);
    if (filtered.isEmpty) {
      return false;
    }

    _appointments.removeAt(index);
    return true;
  }

  void clear() {
    _appointments.clear();
    _lastId = 0;
    _currentUserId = null;
    _bypassRLS = false;
  }
}
