import 'package:equatable/equatable.dart';

// Events
abstract class SimpleSignupEvent extends Equatable {
  const SimpleSignupEvent();

  @override
  List<Object?> get props => [];
}

class SimpleSignupSubmitted extends SimpleSignupEvent {
  final String email;
  final String password;

  const SimpleSignupSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// States
abstract class SimpleSignupState extends Equatable {
  const SimpleSignupState();

  @override
  List<Object?> get props => [];
}

class SimpleSignupInitial extends SimpleSignupState {}

class SimpleSignupLoading extends SimpleSignupState {}

class SimpleSignupSuccess extends SimpleSignupState {
  final String authToken;

  const SimpleSignupSuccess({required this.authToken});

  @override
  List<Object?> get props => [authToken];
}

class SimpleSignupFailure extends SimpleSignupState {
  final String error;

  const SimpleSignupFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
