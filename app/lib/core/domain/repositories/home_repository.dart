import 'package:common/common.dart';

abstract class HomeRepository {
  Future<HomeSummary> fetchSummary({DateTime? referenceDate, int? therapistId});
}
