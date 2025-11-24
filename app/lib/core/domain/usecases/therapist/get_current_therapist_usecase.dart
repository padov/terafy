import 'package:terafy/core/domain/repositories/therapist_repository.dart';

class GetCurrentTherapistUseCase {
  final TherapistRepository repository;

  GetCurrentTherapistUseCase(this.repository);

  Future<Map<String, dynamic>> call() {
    return repository.getCurrentTherapist();
  }
}
