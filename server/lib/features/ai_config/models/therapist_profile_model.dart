class TherapistProfileModel {
  // Section 2: Approach
  final List<String> approaches;
  final String approachDescription;

  // Section 3: Values
  final String changeVision;
  final String therapeuticPosture;
  final String therapistRole;
  final String bondImportance;

  // Section 4: Focus
  final List<String> sessionPriorities;
  final String interestAreas;

  // Section 5: Methodology
  final String sessionFormat;
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
}
