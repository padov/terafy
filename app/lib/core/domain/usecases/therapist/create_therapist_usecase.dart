import 'package:terafy/core/domain/entities/therapist_signup_input.dart';
import 'package:terafy/core/domain/repositories/therapist_repository.dart';

class CreateTherapistUseCase {
  final TherapistRepository repository;

  CreateTherapistUseCase(this.repository);

  Future<void> call({required TherapistSignupInput input}) {
    return repository.createTherapist(input: input);
  }
}
