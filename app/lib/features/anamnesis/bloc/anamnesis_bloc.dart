import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/repositories/anamnesis_repository.dart';
import 'package:terafy/core/domain/repositories/anamnesis_template_repository.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';
import 'anamnesis_bloc_models.dart';

class AnamnesisBloc extends Bloc<AnamnesisEvent, AnamnesisState> {
  AnamnesisBloc({
    required AnamnesisRepository anamnesisRepository,
    required AnamnesisTemplateRepository templateRepository,
  }) : _anamnesisRepository = anamnesisRepository,
       _templateRepository = templateRepository,
       super(const AnamnesisInitial()) {
    on<LoadTemplates>(_onLoadTemplates);
    on<LoadTemplateById>(_onLoadTemplateById);
    on<LoadAnamnesisByPatientId>(_onLoadAnamnesisByPatientId);
    on<LoadAnamnesisById>(_onLoadAnamnesisById);
    on<CreateAnamnesis>(_onCreateAnamnesis);
    on<UpdateAnamnesis>(_onUpdateAnamnesis);
    on<UpdateAnamnesisData>(_onUpdateAnamnesisData);
    on<CompleteAnamnesis>(_onCompleteAnamnesis);
    on<DeleteAnamnesis>(_onDeleteAnamnesis);
    on<ResetAnamnesisState>(_onResetAnamnesisState);
    on<CreateTemplate>(_onCreateTemplate);
    on<UpdateTemplate>(_onUpdateTemplate);
    on<DeleteTemplate>(_onDeleteTemplate);
    on<CreateInvite>(_onCreateInvite);
  }

  Future<void> _onCreateInvite(CreateInvite event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final link = await _anamnesisRepository.createInvite(event.patientId, event.templateId);
      emit(InviteCreated(link: link, message: 'Convite criado com sucesso'));
    } catch (e) {
      emit(AnamnesisError('Erro ao criar convite: ${e.toString()}'));
    }
  }

  final AnamnesisRepository _anamnesisRepository;
  final AnamnesisTemplateRepository _templateRepository;

  Future<void> _onLoadTemplates(LoadTemplates event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final templates = await _templateRepository.fetchTemplates(category: event.category, isSystem: event.isSystem);

      emit(TemplatesLoaded(templates: templates));
    } catch (e) {
      emit(AnamnesisError('Erro ao carregar templates: ${e.toString()}'));
    }
  }

  Future<void> _onLoadTemplateById(LoadTemplateById event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final template = await _templateRepository.fetchTemplateById(event.templateId);

      if (template == null) {
        emit(const AnamnesisError('Template não encontrado'));
        return;
      }

      final currentState = state;
      if (currentState is TemplatesLoaded) {
        emit(currentState.copyWith(selectedTemplate: template));
      } else {
        emit(TemplatesLoaded(templates: [], selectedTemplate: template));
      }
    } catch (e) {
      emit(AnamnesisError('Erro ao carregar template: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAnamnesisByPatientId(LoadAnamnesisByPatientId event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final anamnesis = await _anamnesisRepository.fetchAnamnesisByPatientId(event.patientId);

      if (anamnesis == null) {
        // Retorna para estado inicial quando não há anamnese (não é erro)
        emit(const AnamnesisInitial());
        return;
      }

      // Carrega template se houver templateId
      AnamnesisTemplate? template;
      if (anamnesis.templateId != null) {
        try {
          template = await _templateRepository.fetchTemplateById(anamnesis.templateId!);
        } catch (e) {
          // Se não conseguir carregar template, continua sem template
        }
      }

      emit(AnamnesisLoaded(anamnesis: anamnesis, template: template));
    } catch (e) {
      emit(AnamnesisError('Erro ao carregar anamnese: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAnamnesisById(LoadAnamnesisById event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final anamnesis = await _anamnesisRepository.fetchAnamnesisById(event.id);

      if (anamnesis == null) {
        emit(const AnamnesisError('Anamnese não encontrada'));
        return;
      }

      // Carrega template se houver templateId
      AnamnesisTemplate? template;
      if (anamnesis.templateId != null) {
        template = await _templateRepository.fetchTemplateById(anamnesis.templateId!);
      }

      emit(AnamnesisLoaded(anamnesis: anamnesis, template: template));
    } catch (e) {
      emit(AnamnesisError('Erro ao carregar anamnese: ${e.toString()}'));
    }
  }

  Future<void> _onCreateAnamnesis(CreateAnamnesis event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final created = await _anamnesisRepository.createAnamnesis(event.anamnesis);

      emit(AnamnesisSuccess(anamnesis: created));
    } catch (e) {
      emit(AnamnesisError('Erro ao criar anamnese: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAnamnesis(UpdateAnamnesis event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final updated = await _anamnesisRepository.updateAnamnesis(event.id, event.anamnesis);

      emit(AnamnesisSuccess(anamnesis: updated, message: 'Anamnese atualizada com sucesso'));
    } catch (e) {
      emit(AnamnesisError('Erro ao atualizar anamnese: ${e.toString()}'));
    }
  }

  void _onUpdateAnamnesisData(UpdateAnamnesisData event, Emitter<AnamnesisState> emit) {
    final currentState = state;
    if (currentState is AnamnesisEditing) {
      final updatedData = Map<String, dynamic>.from(currentState.data);
      updatedData.addAll(event.data);

      emit(currentState.copyWith(data: updatedData));
    }
  }

  Future<void> _onCompleteAnamnesis(CompleteAnamnesis event, Emitter<AnamnesisState> emit) async {
    final currentState = state;
    if (currentState is! AnamnesisLoaded) {
      emit(const AnamnesisError('Anamnese não carregada'));
      return;
    }

    emit(const AnamnesisLoading());

    try {
      final anamnesis = currentState.anamnesis.copyWith(completedAt: DateTime.now());

      final updated = await _anamnesisRepository.updateAnamnesis(event.id, anamnesis);

      emit(AnamnesisSuccess(anamnesis: updated, message: 'Anamnese marcada como completa'));
    } catch (e) {
      emit(AnamnesisError('Erro ao completar anamnese: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAnamnesis(DeleteAnamnesis event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      await _anamnesisRepository.deleteAnamnesis(event.id);

      emit(
        AnamnesisSuccess(
          anamnesis: Anamnesis(
            id: '',
            patientId: '',
            therapistId: '',
            data: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          message: 'Anamnese deletada com sucesso',
        ),
      );
    } catch (e) {
      emit(AnamnesisError('Erro ao deletar anamnese: ${e.toString()}'));
    }
  }

  void _onResetAnamnesisState(ResetAnamnesisState event, Emitter<AnamnesisState> emit) {
    emit(const AnamnesisInitial());
  }

  Future<void> _onCreateTemplate(CreateTemplate event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final created = await _templateRepository.createTemplate(event.template);
      emit(TemplateOperationSuccess(template: created, message: 'Modelo criado com sucesso'));
    } catch (e) {
      emit(AnamnesisError('Erro ao criar modelo: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateTemplate(UpdateTemplate event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      final updated = await _templateRepository.updateTemplate(event.id, event.template);
      emit(TemplateOperationSuccess(template: updated, message: 'Modelo atualizado com sucesso'));
    } catch (e) {
      emit(AnamnesisError('Erro ao atualizar modelo: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTemplate(DeleteTemplate event, Emitter<AnamnesisState> emit) async {
    emit(const AnamnesisLoading());

    try {
      await _templateRepository.deleteTemplate(event.id);
      emit(const TemplateOperationSuccess(message: 'Modelo excluído com sucesso'));
    } catch (e) {
      emit(AnamnesisError('Erro ao excluir modelo: ${e.toString()}'));
    }
  }
}
