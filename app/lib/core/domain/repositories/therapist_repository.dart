import 'package:terafy/core/domain/entities/therapist_signup_input.dart';
import 'package:common/common.dart';

abstract class TherapistRepository {
  Future<void> createTherapist({required TherapistSignupInput input});

  Future<Map<String, dynamic>> getCurrentTherapist();

  Future<Map<String, dynamic>> updateTherapist({required Therapist therapist});
}
