import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:terafy/core/domain/usecases/patient/create_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patient_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/get_patients_usecase.dart';
import 'package:terafy/core/domain/usecases/patient/update_patient_usecase.dart';
import 'package:terafy/core/services/patients_cache_service.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'patients_bloc_models.dart';

class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  PatientsBloc({
    required GetPatientsUseCase getPatientsUseCase,
    required CreatePatientUseCase createPatientUseCase,
    required GetPatientUseCase getPatientUseCase,
    required UpdatePatientUseCase updatePatientUseCase,
    required PatientsCacheService patientsCacheService,
    SubscriptionRepository? subscriptionRepository,
  }) : _getPatientsUseCase = getPatientsUseCase,
       _createPatientUseCase = createPatientUseCase,
       _getPatientUseCase = getPatientUseCase,
       _updatePatientUseCase = updatePatientUseCase,
       _patientsCacheService = patientsCacheService,
       _subscriptionRepository = subscriptionRepository,
       super(const PatientsInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<RefreshPatients>(_onRefreshPatients);
    on<SearchPatients>(_onSearchPatients);
    on<FilterPatientsByStatus>(_onFilterPatientsByStatus);
    on<AddQuickPatient>(_onAddQuickPatient);
    on<SelectPatient>(_onSelectPatient);
    on<RequestAIAnalysis>(_onRequestAIAnalysis);
    on<ResetPatientsView>(_onResetPatientsView);
    on<UpdatePatient>(_onUpdatePatient);
    on<UpdatePatientNotes>(_onUpdatePatientNotes);
  }

  final GetPatientsUseCase _getPatientsUseCase;
  final CreatePatientUseCase _createPatientUseCase;
  final GetPatientUseCase _getPatientUseCase;
  final UpdatePatientUseCase _updatePatientUseCase;
  final PatientsCacheService _patientsCacheService;
  final SubscriptionRepository? _subscriptionRepository;
  PatientsLoaded? _lastLoadedState;
  String? _currentSearchQuery;
  PatientStatus? _currentStatusFilter = PatientStatus.active;

  Future<void> _onLoadPatients(LoadPatients event, Emitter<PatientsState> emit) async {
    final cachedList = _patientsCacheService.getPatients();
    if (cachedList != null && cachedList.isNotEmpty) {
      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: cachedList,
          filteredPatients: _applyFilters(
            cachedList,
            searchQuery: _currentSearchQuery,
            statusFilter: _currentStatusFilter,
          ),
          searchQuery: _currentSearchQuery,
          statusFilter: _currentStatusFilter,
        ),
      );
    } else {
      emit(const PatientsLoading());
    }

    try {
      final patients = await _getPatientsUseCase();
      _patientsCacheService.savePatients(patients);

      final previous = _lastLoadedState;
      final searchQuery = _currentSearchQuery ?? previous?.searchQuery;
      final statusFilter = _currentStatusFilter ?? previous?.statusFilter ?? PatientStatus.active;

      // Busca informações de uso se subscription repository estiver disponível
      int? patientCount;
      int? patientLimit;
      bool? canCreatePatient;

      if (_subscriptionRepository != null) {
        try {
          final usage = await _subscriptionRepository.getUsageInfo();
          patientCount = usage.patientCount;
          patientLimit = usage.patientLimit;
          canCreatePatient = usage.canCreatePatient;
        } catch (e) {
          // Se falhar, usa contagem de pacientes como fallback
          patientCount = patients.length;
        }
      } else {
        patientCount = patients.length;
      }

      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: patients,
          filteredPatients: _applyFilters(patients, searchQuery: searchQuery, statusFilter: statusFilter),
          searchQuery: searchQuery,
          statusFilter: statusFilter,
          patientCount: patientCount,
          patientLimit: patientLimit,
          canCreatePatient: canCreatePatient,
        ),
      );
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }

  Future<void> _onRefreshPatients(RefreshPatients event, Emitter<PatientsState> emit) async {
    add(const LoadPatients());
  }

  void _onSearchPatients(SearchPatients event, Emitter<PatientsState> emit) {
    if (state is PatientsLoaded) {
      final currentState = state as PatientsLoaded;
      _currentSearchQuery = event.query.isEmpty ? null : event.query;

      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: currentState.patients,
          filteredPatients: _applyFilters(
            currentState.patients,
            searchQuery: _currentSearchQuery,
            statusFilter: currentState.statusFilter,
          ),
          searchQuery: _currentSearchQuery,
          statusFilter: currentState.statusFilter,
        ),
      );
    }
  }

  void _onFilterPatientsByStatus(FilterPatientsByStatus event, Emitter<PatientsState> emit) {
    if (state is PatientsLoaded) {
      final currentState = state as PatientsLoaded;
      _currentStatusFilter = event.status;

      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: currentState.patients,
          filteredPatients: _applyFilters(
            currentState.patients,
            searchQuery: currentState.searchQuery,
            statusFilter: _currentStatusFilter,
          ),
          searchQuery: currentState.searchQuery,
          statusFilter: _currentStatusFilter,
        ),
      );
    }
  }

  Future<void> _onAddQuickPatient(AddQuickPatient event, Emitter<PatientsState> emit) async {
    emit(const PatientAdding());

    try {
      // Verifica limite antes de criar
      if (_subscriptionRepository != null) {
        try {
          final usage = await _subscriptionRepository.getUsageInfo();
          if (!usage.canCreatePatient) {
            emit(
              PatientsError(
                'Limite de pacientes atingido. Você possui ${usage.patientCount} de ${usage.patientLimit} pacientes permitidos no seu plano atual. Faça upgrade para adicionar mais pacientes.',
              ),
            );
            return;
          }
        } catch (e) {
          // Se falhar na verificação, continua (backend também valida)
        }
      }

      final createdPatient = await _createPatientUseCase(
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        birthDate: event.dateOfBirth,
      );

      emit(PatientAdded(createdPatient));

      final patients = await _getPatientsUseCase();
      _patientsCacheService.savePatients(patients);

      // Busca informações de uso atualizadas
      int? patientCount;
      int? patientLimit;
      bool? canCreatePatient;

      if (_subscriptionRepository != null) {
        try {
          final usage = await _subscriptionRepository.getUsageInfo();
          patientCount = usage.patientCount;
          patientLimit = usage.patientLimit;
          canCreatePatient = usage.canCreatePatient;
        } catch (e) {
          patientCount = patients.length;
        }
      } else {
        patientCount = patients.length;
      }

      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: patients,
          filteredPatients: _applyFilters(
            patients,
            searchQuery: _currentSearchQuery,
            statusFilter: _currentStatusFilter,
          ),
          searchQuery: _currentSearchQuery,
          statusFilter: _currentStatusFilter,
          patientCount: patientCount,
          patientLimit: patientLimit,
          canCreatePatient: canCreatePatient,
        ),
      );
    } catch (e) {
      emit(PatientsError(e.toString()));
    }
  }

  Future<void> _onSelectPatient(SelectPatient event, Emitter<PatientsState> emit) async {
    Patient? fallback;
    if (state is PatientsLoaded) {
      final currentState = state as PatientsLoaded;
      fallback = currentState.patients.firstWhere(
        (p) => p.id == event.patientId,
        orElse: () => fallback ?? currentState.patients.first,
      );
      emit(PatientSelected(fallback));
    } else if (state is PatientSelected) {
      fallback = (state as PatientSelected).patient;
    }

    try {
      final patient = await _getPatientUseCase(event.patientId);
      emit(PatientSelected(patient));
    } catch (e) {
      if (fallback != null) {
        emit(PatientSelected(fallback));
      } else {
        emit(PatientsError(e.toString()));
      }
    }
  }

  Future<void> _onRequestAIAnalysis(RequestAIAnalysis event, Emitter<PatientsState> emit) async {
    if (state is PatientSelected) {
      final currentState = state as PatientSelected;

      emit(AIAnalysisLoading(currentState.patient));

      try {
        await Future.delayed(const Duration(seconds: 2));

        final analysis = _generateMockAIAnalysis(currentState.patient);

        emit(AIAnalysisLoaded(patient: currentState.patient, analysis: analysis));
      } catch (e) {
        emit(PatientsError(e.toString()));
      }
    }
  }

  void _onResetPatientsView(ResetPatientsView event, Emitter<PatientsState> emit) {
    if (_lastLoadedState != null) {
      final cachedState = _lastLoadedState!;
      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: cachedState.patients,
          filteredPatients: _applyFilters(
            cachedState.patients,
            searchQuery: cachedState.searchQuery,
            statusFilter: cachedState.statusFilter,
          ),
          searchQuery: cachedState.searchQuery,
          statusFilter: cachedState.statusFilter,
        ),
      );
      return;
    }

    final cached = _patientsCacheService.getPatients();
    if (cached != null && cached.isNotEmpty) {
      _emitLoaded(
        emit,
        PatientsLoaded(
          patients: cached,
          filteredPatients: _applyFilters(cached, searchQuery: _currentSearchQuery, statusFilter: _currentStatusFilter),
          searchQuery: _currentSearchQuery,
          statusFilter: _currentStatusFilter,
        ),
      );
      return;
    }

    add(const LoadPatients());
  }

  String _generateMockAIAnalysis(Patient patient) {
    return '''
🤖 Análise IA - ${patient.fullName}

📊 Perfil do Paciente:
• Idade: ${patient.age ?? 'Não informada'} anos
• Status: ${_getStatusText(patient.status)}
• Total de Sessões: ${patient.totalSessions}
• Cadastro: ${patient.completionPercentage.toStringAsFixed(0)}% completo

💡 Insights:
• ${patient.totalSessions < 5 ? 'Paciente em fase inicial de tratamento. Recomenda-se estabelecer rapport e definir objetivos terapêuticos claros.' : 'Paciente em acompanhamento regular. Avaliar progresso e ajustar plano terapêutico conforme necessário.'}
• ${patient.completionPercentage < 50 ? 'Recomenda-se completar o cadastro para análise mais aprofundada.' : 'Cadastro suficientemente completo para análise detalhada.'}

⚠️ Pontos de Atenção:
• ${patient.lastSessionDate != null ? 'Última sessão realizada há ${DateTime.now().difference(patient.lastSessionDate!).inDays} dias' : 'Nenhuma sessão registrada ainda'}
• ${patient.emergencyContact == null ? 'Contato de emergência não cadastrado' : 'Contato de emergência disponível'}

📋 Recomendações:
1. Atualizar observações após cada sessão
2. Revisar plano terapêutico a cada 10 sessões
3. Considerar avaliações periódicas de progresso

Esta análise foi gerada automaticamente e deve ser complementada com avaliação clínica profissional.
''';
  }

  String _getStatusText(PatientStatus status) {
    switch (status) {
      case PatientStatus.active:
        return 'Ativo';
      case PatientStatus.evaluated:
        return 'Avaliado';
      case PatientStatus.inactive:
        return 'Inativo';
      case PatientStatus.discharged:
        return 'Em Alta';
      case PatientStatus.dischargeCompleted:
        return 'Alta Concluída';
    }
  }

  List<Patient> _applyFilters(List<Patient> patients, {String? searchQuery, PatientStatus? statusFilter}) {
    Iterable<Patient> filtered = patients;

    if (statusFilter != null) {
      filtered = filtered.where((patient) => patient.status == statusFilter);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((patient) {
        final matchesName = patient.fullName.toLowerCase().contains(query);
        final matchesPhone = patient.phone.contains(query);
        final matchesEmail = patient.email?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesPhone || matchesEmail;
      });
    }

    return filtered.toList();
  }

  Future<void> _onUpdatePatient(UpdatePatient event, Emitter<PatientsState> emit) async {
    Patient? currentPatient;
    if (state is PatientSelected) {
      currentPatient = (state as PatientSelected).patient;
      emit(PatientUpdating(currentPatient));
    } else if (state is AIAnalysisLoading) {
      currentPatient = (state as AIAnalysisLoading).patient;
      emit(PatientUpdating(currentPatient));
    } else if (state is PatientUpdating) {
      currentPatient = (state as PatientUpdating).patient;
    } else if (state is PatientUpdated) {
      currentPatient = (state as PatientUpdated).patient;
      emit(PatientUpdating(currentPatient));
    }

    try {
      final updatedPatient = await _updatePatientUseCase(patient: event.patient);

      // Atualiza cache
      final cached = _patientsCacheService.getPatients();
      if (cached != null) {
        final index = cached.indexWhere((p) => p.id == updatedPatient.id);
        if (index != -1) {
          // Cria uma nova lista mutável para evitar erro de lista imutável
          final updatedCache = List<Patient>.from(cached);
          updatedCache[index] = updatedPatient;
          _patientsCacheService.savePatients(updatedCache);
        }
      }

      // Se estava visualizando o paciente, volta para PatientSelected com dados atualizados
      if (currentPatient != null) {
        emit(PatientSelected(updatedPatient));
      } else {
        // Se não estava visualizando, emite PatientUpdated
        emit(PatientUpdated(updatedPatient));
      }

      // Atualiza lista se estiver em estado de lista (sem emitir, apenas atualiza o cache)
      if (_lastLoadedState != null) {
        final updatedList = _lastLoadedState!.patients.map((p) {
          return p.id == updatedPatient.id ? updatedPatient : p;
        }).toList();

        // Atualiza o estado da lista apenas se não estivermos visualizando o paciente
        if (currentPatient == null) {
          _emitLoaded(
            emit,
            PatientsLoaded(
              patients: updatedList,
              filteredPatients: _applyFilters(
                updatedList,
                searchQuery: _lastLoadedState!.searchQuery,
                statusFilter: _lastLoadedState!.statusFilter,
              ),
              searchQuery: _lastLoadedState!.searchQuery,
              statusFilter: _lastLoadedState!.statusFilter,
            ),
          );
        } else {
          // Apenas atualiza o cache interno sem emitir novo estado
          _lastLoadedState = PatientsLoaded(
            patients: updatedList,
            filteredPatients: _applyFilters(
              updatedList,
              searchQuery: _lastLoadedState!.searchQuery,
              statusFilter: _lastLoadedState!.statusFilter,
            ),
            searchQuery: _lastLoadedState!.searchQuery,
            statusFilter: _lastLoadedState!.statusFilter,
          );
        }
      }
    } catch (e) {
      if (currentPatient != null) {
        emit(PatientSelected(currentPatient));
      }
      emit(PatientsError(e.toString()));
    }
  }

  Future<void> _onUpdatePatientNotes(UpdatePatientNotes event, Emitter<PatientsState> emit) async {
    Patient? currentPatient;
    if (state is PatientSelected) {
      currentPatient = (state as PatientSelected).patient;
    } else if (state is AIAnalysisLoading) {
      currentPatient = (state as AIAnalysisLoading).patient;
    } else if (state is PatientUpdating) {
      currentPatient = (state as PatientUpdating).patient;
    } else if (state is PatientUpdated) {
      currentPatient = (state as PatientUpdated).patient;
    }

    if (currentPatient == null) {
      emit(const PatientsError('Paciente não encontrado'));
      return;
    }

    // Verifica se o pacienteId corresponde
    if (currentPatient.id != event.patientId) {
      emit(const PatientsError('Paciente não encontrado'));
      return;
    }

    final updatedPatient = currentPatient.copyWith(notes: (event.notes?.isEmpty ?? true) ? null : event.notes);
    add(UpdatePatient(updatedPatient));
  }

  void _emitLoaded(Emitter<PatientsState> emit, PatientsLoaded state) {
    _currentSearchQuery = state.searchQuery;
    _currentStatusFilter = state.statusFilter;
    _lastLoadedState = state;
    emit(state);
  }
}
