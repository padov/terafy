import 'package:equatable/equatable.dart';
import 'package:terafy/core/domain/entities/client.dart';

// --- EVENTOS ---
abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends LoginEvent {
  final String email;
  final String password;
  final bool isBiometricsEnabled;

  const LoginButtonPressed({
    required this.email,
    required this.password,
    required this.isBiometricsEnabled,
  });

  @override
  List<Object> get props => [email, password, isBiometricsEnabled];
}

class LoginWithGooglePressed extends LoginEvent {}

class LoginWithBiometrics extends LoginEvent {}

class CheckBiometricLogin extends LoginEvent {}

class CheckTokenValidity extends LoginEvent {}

class BiometricsPreferenceChanged extends LoginEvent {
  final bool enabled;

  const BiometricsPreferenceChanged({required this.enabled});

  @override
  List<Object> get props => [enabled];
}

class LogoutPressed extends LoginEvent {}

// --- ESTADOS ---
abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final Client client;
  final bool requiresProfileCompletion;

  const LoginSuccess({
    required this.client,
    this.requiresProfileCompletion = false,
  });

  @override
  List<Object> get props => [client, requiresProfileCompletion];
}

// NOTA: Este estado não está sendo usado atualmente.
// A lógica de biometria foi refatorada para solicitar confirmação biométrica
// diretamente no LoginButtonPressed após o login bem-sucedido.
// Mantido para referência futura caso seja necessário.
// ignore: unused_element
class LoginSuccessAskBiometrics extends LoginState {
  final Client client;

  const LoginSuccessAskBiometrics({required this.client});

  @override
  List<Object> get props => [client];
}

class LoginFailure extends LoginState {
  final String error;

  const LoginFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class LogoutSuccess extends LoginState {}
