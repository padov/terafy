import 'package:terafy/core/domain/repositories/therapist_repository.dart';
import 'package:common/common.dart';

class UpdateTherapistUseCase {
  final TherapistRepository repository;

  UpdateTherapistUseCase(this.repository);

  Future<Map<String, dynamic>> call({required Therapist therapist}) {
    return repository.updateTherapist(therapist: therapist);
  }
}
