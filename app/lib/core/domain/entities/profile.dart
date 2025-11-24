import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  final String id;
  final String name;
  final bool? needsAuthorization;
  final int? limitVouchersADay;
  final int? limitVouchersRDay;
  final int? limitVouchersA30Day;
  final int? limitVouchersR30Day;
  final bool? allowVouchersAAndRDay;
  final double? limitReaisADay;
  final double? limitReaisAMonth;
  final bool? isDefaultProfile;
  final int? qtyActiveClients;

  const Profile({
    required this.id,
    required this.name,
    this.needsAuthorization,
    this.limitVouchersADay,
    this.limitVouchersRDay,
    this.limitVouchersA30Day,
    this.limitVouchersR30Day,
    this.allowVouchersAAndRDay,
    this.limitReaisADay,
    this.limitReaisAMonth,
    this.isDefaultProfile,
    this.qtyActiveClients,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    needsAuthorization,
    limitVouchersADay,
    limitVouchersRDay,
    limitVouchersA30Day,
    limitVouchersR30Day,
    allowVouchersAAndRDay,
    limitReaisADay,
    limitReaisAMonth,
    isDefaultProfile,
    qtyActiveClients,
  ];
}
