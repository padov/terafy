import 'package:equatable/equatable.dart';

class TherapistProfileModel extends Equatable {
  // Section 2: Approach
  final List<String> approaches;
  final String approachDescription;

  // Section 3: Values
  final String changeVision;
  final String therapeuticPosture; // Diretiva, Não-diretiva, Mista
  final String therapistRole;
  final String bondImportance; // Fundamental, Importante, Contextual

  // Section 4: Focus
  final List<String> sessionPriorities; // Ordered list
  final String interestAreas;

  // Section 5: Methodology
  final String sessionFormat; // Estruturada, Semi, Livre
  final String frequentTechniques;
  final String recommendedFrequency;
  final String typicalDuration;

  // Section 6: Evaluation
  final String diagnosisUsage;
  final String evaluationElements;
  final String progressIndicators;

  // Section 7: Specific Situations
  final String resistanceHandling;
  final String crisisHandling;
  final String stagnationHandling;
  final String terminationHandling;

  // Section 8: Mental Health Beliefs
  final String sufferingNature;
  final String changePotential;
  final String medicationView;
  final String cureView;

  // Section 9: Communication
  final String communicationTone;
  final String humorUsage;
  final String confrontationStyle;
  final String selfDisclosure;

  // Section 10: Ethics
  final String outOfSessionContact;
  final String treatmentDurationView;
  final String untreatableSituations;

  // Section 11: AI Instructions
  final String aiAnalysisFocus;
  final String aiTone;
  final String aiAlerts;
  final List<String> aiSuggestionsDesired;
  final String aiResponseFormat;

  const TherapistProfileModel({
    this.approaches = const [],
    this.approachDescription = '',
    this.changeVision = '',
    this.therapeuticPosture = '',
    this.therapistRole = '',
    this.bondImportance = '',
    this.sessionPriorities = const [],
    this.interestAreas = '',
    this.sessionFormat = '',
    this.frequentTechniques = '',
    this.recommendedFrequency = '',
    this.typicalDuration = '',
    this.diagnosisUsage = '',
    this.evaluationElements = '',
    this.progressIndicators = '',
    this.resistanceHandling = '',
    this.crisisHandling = '',
    this.stagnationHandling = '',
    this.terminationHandling = '',
    this.sufferingNature = '',
    this.changePotential = '',
    this.medicationView = '',
    this.cureView = '',
    this.communicationTone = '',
    this.humorUsage = '',
    this.confrontationStyle = '',
    this.selfDisclosure = '',
    this.outOfSessionContact = '',
    this.treatmentDurationView = '',
    this.untreatableSituations = '',
    this.aiAnalysisFocus = '',
    this.aiTone = '',
    this.aiAlerts = '',
    this.aiSuggestionsDesired = const [],
    this.aiResponseFormat = '',
  });

  TherapistProfileModel copyWith({
    List<String>? approaches,
    String? approachDescription,
    String? changeVision,
    String? therapeuticPosture,
    String? therapistRole,
    String? bondImportance,
    List<String>? sessionPriorities,
    String? interestAreas,
    String? sessionFormat,
    String? frequentTechniques,
    String? recommendedFrequency,
    String? typicalDuration,
    String? diagnosisUsage,
    String? evaluationElements,
    String? progressIndicators,
    String? resistanceHandling,
    String? crisisHandling,
    String? stagnationHandling,
    String? terminationHandling,
    String? sufferingNature,
    String? changePotential,
    String? medicationView,
    String? cureView,
    String? communicationTone,
    String? humorUsage,
    String? confrontationStyle,
    String? selfDisclosure,
    String? outOfSessionContact,
    String? treatmentDurationView,
    String? untreatableSituations,
    String? aiAnalysisFocus,
    String? aiTone,
    String? aiAlerts,
    List<String>? aiSuggestionsDesired,
    String? aiResponseFormat,
  }) {
    return TherapistProfileModel(
      approaches: approaches ?? this.approaches,
      approachDescription: approachDescription ?? this.approachDescription,
      changeVision: changeVision ?? this.changeVision,
      therapeuticPosture: therapeuticPosture ?? this.therapeuticPosture,
      therapistRole: therapistRole ?? this.therapistRole,
      bondImportance: bondImportance ?? this.bondImportance,
      sessionPriorities: sessionPriorities ?? this.sessionPriorities,
      interestAreas: interestAreas ?? this.interestAreas,
      sessionFormat: sessionFormat ?? this.sessionFormat,
      frequentTechniques: frequentTechniques ?? this.frequentTechniques,
      recommendedFrequency: recommendedFrequency ?? this.recommendedFrequency,
      typicalDuration: typicalDuration ?? this.typicalDuration,
      diagnosisUsage: diagnosisUsage ?? this.diagnosisUsage,
      evaluationElements: evaluationElements ?? this.evaluationElements,
      progressIndicators: progressIndicators ?? this.progressIndicators,
      resistanceHandling: resistanceHandling ?? this.resistanceHandling,
      crisisHandling: crisisHandling ?? this.crisisHandling,
      stagnationHandling: stagnationHandling ?? this.stagnationHandling,
      terminationHandling: terminationHandling ?? this.terminationHandling,
      sufferingNature: sufferingNature ?? this.sufferingNature,
      changePotential: changePotential ?? this.changePotential,
      medicationView: medicationView ?? this.medicationView,
      cureView: cureView ?? this.cureView,
      communicationTone: communicationTone ?? this.communicationTone,
      humorUsage: humorUsage ?? this.humorUsage,
      confrontationStyle: confrontationStyle ?? this.confrontationStyle,
      selfDisclosure: selfDisclosure ?? this.selfDisclosure,
      outOfSessionContact: outOfSessionContact ?? this.outOfSessionContact,
      treatmentDurationView: treatmentDurationView ?? this.treatmentDurationView,
      untreatableSituations: untreatableSituations ?? this.untreatableSituations,
      aiAnalysisFocus: aiAnalysisFocus ?? this.aiAnalysisFocus,
      aiTone: aiTone ?? this.aiTone,
      aiAlerts: aiAlerts ?? this.aiAlerts,
      aiSuggestionsDesired: aiSuggestionsDesired ?? this.aiSuggestionsDesired,
      aiResponseFormat: aiResponseFormat ?? this.aiResponseFormat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approaches': approaches,
      'approachDescription': approachDescription,
      'changeVision': changeVision,
      'therapeuticPosture': therapeuticPosture,
      'therapistRole': therapistRole,
      'bondImportance': bondImportance,
      'sessionPriorities': sessionPriorities,
      'interestAreas': interestAreas,
      'sessionFormat': sessionFormat,
      'frequentTechniques': frequentTechniques,
      'recommendedFrequency': recommendedFrequency,
      'typicalDuration': typicalDuration,
      'diagnosisUsage': diagnosisUsage,
      'evaluationElements': evaluationElements,
      'progressIndicators': progressIndicators,
      'resistanceHandling': resistanceHandling,
      'crisisHandling': crisisHandling,
      'stagnationHandling': stagnationHandling,
      'terminationHandling': terminationHandling,
      'sufferingNature': sufferingNature,
      'changePotential': changePotential,
      'medicationView': medicationView,
      'cureView': cureView,
      'communicationTone': communicationTone,
      'humorUsage': humorUsage,
      'confrontationStyle': confrontationStyle,
      'selfDisclosure': selfDisclosure,
      'outOfSessionContact': outOfSessionContact,
      'treatmentDurationView': treatmentDurationView,
      'untreatableSituations': untreatableSituations,
      'aiAnalysisFocus': aiAnalysisFocus,
      'aiTone': aiTone,
      'aiAlerts': aiAlerts,
      'aiSuggestionsDesired': aiSuggestionsDesired,
      'aiResponseFormat': aiResponseFormat,
    };
  }

  factory TherapistProfileModel.fromJson(Map<String, dynamic> json) {
    return TherapistProfileModel(
      approaches: List<String>.from(json['approaches'] ?? []),
      approachDescription: json['approachDescription'] ?? '',
      changeVision: json['changeVision'] ?? '',
      therapeuticPosture: json['therapeuticPosture'] ?? '',
      therapistRole: json['therapistRole'] ?? '',
      bondImportance: json['bondImportance'] ?? '',
      sessionPriorities: List<String>.from(json['sessionPriorities'] ?? []),
      interestAreas: json['interestAreas'] ?? '',
      sessionFormat: json['sessionFormat'] ?? '',
      frequentTechniques: json['frequentTechniques'] ?? '',
      recommendedFrequency: json['recommendedFrequency'] ?? '',
      typicalDuration: json['typicalDuration'] ?? '',
      diagnosisUsage: json['diagnosisUsage'] ?? '',
      evaluationElements: json['evaluationElements'] ?? '',
      progressIndicators: json['progressIndicators'] ?? '',
      resistanceHandling: json['resistanceHandling'] ?? '',
      crisisHandling: json['crisisHandling'] ?? '',
      stagnationHandling: json['stagnationHandling'] ?? '',
      terminationHandling: json['terminationHandling'] ?? '',
      sufferingNature: json['sufferingNature'] ?? '',
      changePotential: json['changePotential'] ?? '',
      medicationView: json['medicationView'] ?? '',
      cureView: json['cureView'] ?? '',
      communicationTone: json['communicationTone'] ?? '',
      humorUsage: json['humorUsage'] ?? '',
      confrontationStyle: json['confrontationStyle'] ?? '',
      selfDisclosure: json['selfDisclosure'] ?? '',
      outOfSessionContact: json['outOfSessionContact'] ?? '',
      treatmentDurationView: json['treatmentDurationView'] ?? '',
      untreatableSituations: json['untreatableSituations'] ?? '',
      aiAnalysisFocus: json['aiAnalysisFocus'] ?? '',
      aiTone: json['aiTone'] ?? '',
      aiAlerts: json['aiAlerts'] ?? '',
      aiSuggestionsDesired: List<String>.from(json['aiSuggestionsDesired'] ?? []),
      aiResponseFormat: json['aiResponseFormat'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    approaches,
    approachDescription,
    changeVision,
    therapeuticPosture,
    therapistRole,
    bondImportance,
    sessionPriorities,
    interestAreas,
    sessionFormat,
    frequentTechniques,
    recommendedFrequency,
    typicalDuration,
    diagnosisUsage,
    evaluationElements,
    progressIndicators,
    resistanceHandling,
    crisisHandling,
    stagnationHandling,
    terminationHandling,
    sufferingNature,
    changePotential,
    medicationView,
    cureView,
    communicationTone,
    humorUsage,
    confrontationStyle,
    selfDisclosure,
    outOfSessionContact,
    treatmentDurationView,
    untreatableSituations,
    aiAnalysisFocus,
    aiTone,
    aiAlerts,
    aiSuggestionsDesired,
    aiResponseFormat,
  ];
}
