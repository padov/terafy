import 'package:equatable/equatable.dart';
import 'package:terafy/features/anamnesis/models/anamnesis.dart';
import 'package:terafy/features/anamnesis/models/anamnesis_template.dart';

// ========== EVENTS ==========

abstract class AnamnesisEvent extends Equatable {
  const AnamnesisEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega templates disponíveis
class LoadTemplates extends AnamnesisEvent {
  final String? category;
  final bool? isSystem;

  const LoadTemplates({this.category, this.isSystem});

  @override
  List<Object?> get props => [category, isSystem];
}

/// Carrega anamnese por ID do paciente
class LoadAnamnesisByPatientId extends AnamnesisEvent {
  final String patientId;

  const LoadAnamnesisByPatientId(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

/// Carrega anamnese por ID
class LoadAnamnesisById extends AnamnesisEvent {
  final String id;

  const LoadAnamnesisById(this.id);

  @override
  List<Object?> get props => [id];
}

/// Carrega template por ID
class LoadTemplateById extends AnamnesisEvent {
  final String templateId;

  const LoadTemplateById(this.templateId);

  @override
  List<Object?> get props => [templateId];
}

/// Cria nova anamnese
class CreateAnamnesis extends AnamnesisEvent {
  final Anamnesis anamnesis;

  const CreateAnamnesis(this.anamnesis);

  @override
  List<Object?> get props => [anamnesis];
}

/// Atualiza anamnese existente
class UpdateAnamnesis extends AnamnesisEvent {
  final String id;
  final Anamnesis anamnesis;

  const UpdateAnamnesis({required this.id, required this.anamnesis});

  @override
  List<Object?> get props => [id, anamnesis];
}

/// Atualiza dados da anamnese em edição
class UpdateAnamnesisData extends AnamnesisEvent {
  final Map<String, dynamic> data;

  const UpdateAnamnesisData(this.data);

  @override
  List<Object?> get props => [data];
}

/// Marca anamnese como completa
class CompleteAnamnesis extends AnamnesisEvent {
  final String id;

  const CompleteAnamnesis(this.id);

  @override
  List<Object?> get props => [id];
}

/// Deleta anamnese
class DeleteAnamnesis extends AnamnesisEvent {
  final String id;

  const DeleteAnamnesis(this.id);

  @override
  List<Object?> get props => [id];
}

/// Reseta o estado
class ResetAnamnesisState extends AnamnesisEvent {
  const ResetAnamnesisState();
}

// ========== TEMPLATE EVENTS ==========

/// Cria novo template
class CreateTemplate extends AnamnesisEvent {
  final AnamnesisTemplate template;

  const CreateTemplate(this.template);

  @override
  List<Object?> get props => [template];
}

/// Atualiza template existente
class UpdateTemplate extends AnamnesisEvent {
  final String id;
  final AnamnesisTemplate template;

  const UpdateTemplate({required this.id, required this.template});

  @override
  List<Object?> get props => [id, template];
}

/// Deleta template
class DeleteTemplate extends AnamnesisEvent {
  final String id;

  const DeleteTemplate(this.id);

  @override
  List<Object?> get props => [id];
}

/// Cria um convite para preenchimento de anamnese
class CreateInvite extends AnamnesisEvent {
  final String patientId;
  final String templateId;

  const CreateInvite({required this.patientId, required this.templateId});

  @override
  List<Object?> get props => [patientId, templateId];
}

// ========== STATES ==========

abstract class AnamnesisState extends Equatable {
  const AnamnesisState();

  @override
  List<Object?> get props => [];
}

class AnamnesisInitial extends AnamnesisState {
  const AnamnesisInitial();
}

class AnamnesisLoading extends AnamnesisState {
  const AnamnesisLoading();
}

class TemplatesLoaded extends AnamnesisState {
  final List<AnamnesisTemplate> templates;
  final AnamnesisTemplate? selectedTemplate;

  const TemplatesLoaded({required this.templates, this.selectedTemplate});

  @override
  List<Object?> get props => [templates, selectedTemplate];

  TemplatesLoaded copyWith({List<AnamnesisTemplate>? templates, AnamnesisTemplate? selectedTemplate}) {
    return TemplatesLoaded(
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    );
  }
}

class AnamnesisLoaded extends AnamnesisState {
  final Anamnesis anamnesis;
  final AnamnesisTemplate? template;

  const AnamnesisLoaded({required this.anamnesis, this.template});

  @override
  List<Object?> get props => [anamnesis, template];

  AnamnesisLoaded copyWith({Anamnesis? anamnesis, AnamnesisTemplate? template}) {
    return AnamnesisLoaded(anamnesis: anamnesis ?? this.anamnesis, template: template ?? this.template);
  }
}

class AnamnesisEditing extends AnamnesisState {
  final Anamnesis? existingAnamnesis;
  final AnamnesisTemplate template;
  final Map<String, dynamic> data;
  final String patientId;
  final String therapistId;
  final String? templateId;

  const AnamnesisEditing({
    this.existingAnamnesis,
    required this.template,
    required this.data,
    required this.patientId,
    required this.therapistId,
    this.templateId,
  });

  @override
  List<Object?> get props => [existingAnamnesis, template, data, patientId, therapistId, templateId];

  AnamnesisEditing copyWith({
    Anamnesis? existingAnamnesis,
    AnamnesisTemplate? template,
    Map<String, dynamic>? data,
    String? patientId,
    String? therapistId,
    String? templateId,
  }) {
    return AnamnesisEditing(
      existingAnamnesis: existingAnamnesis ?? this.existingAnamnesis,
      template: template ?? this.template,
      data: data ?? this.data,
      patientId: patientId ?? this.patientId,
      therapistId: therapistId ?? this.therapistId,
      templateId: templateId ?? this.templateId,
    );
  }
}

class AnamnesisSuccess extends AnamnesisState {
  final Anamnesis anamnesis;
  final String message;

  const AnamnesisSuccess({required this.anamnesis, this.message = 'Anamnese salva com sucesso'});

  @override
  List<Object?> get props => [anamnesis, message];
}

class TemplateOperationSuccess extends AnamnesisState {
  final AnamnesisTemplate? template;
  final String message;

  const TemplateOperationSuccess({this.template, required this.message});

  @override
  List<Object?> get props => [template, message];
}

class InviteCreated extends AnamnesisState {
  final String link;
  final String message;

  const InviteCreated({required this.link, required this.message});

  @override
  List<Object?> get props => [link, message];
}

class AnamnesisError extends AnamnesisState {
  final String message;

  const AnamnesisError(this.message);

  @override
  List<Object?> get props => [message];
}
