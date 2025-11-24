import 'package:equatable/equatable.dart';
import 'package:terafy/core/domain/entities/client_referrer.dart';
import 'package:terafy/core/domain/entities/customer.dart';
import 'package:terafy/core/domain/entities/profile.dart';

class Client extends Equatable {
  final String id;
  final String name;
  final String email;
  final double? economized;
  final String? phone;
  final String? sexo;
  final DateTime? birthday;
  final double? balance;
  final double? balancePts;
  final double? credit;
  final double? debit;
  final String? referralCode;
  final String? cpf;
  final int? qtyGasStations;
  final bool? portabilityHasBeenDone;
  final Customer? customer;
  final Profile? profile;
  final bool? choiceProfile;
  final ClientReferrer? clientReferrer;
  final int?
  accountId; // ID do terapeuta/paciente associado (null = cadastro incompleto)

  const Client({
    required this.id,
    required this.name,
    required this.email,
    this.economized,
    this.phone,
    this.sexo,
    this.birthday,
    this.balance,
    this.balancePts,
    this.credit,
    this.debit,
    this.referralCode,
    this.cpf,
    this.qtyGasStations,
    this.portabilityHasBeenDone,
    this.customer,
    this.profile,
    this.choiceProfile,
    this.clientReferrer,
    this.accountId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    economized,
    phone,
    sexo,
    birthday,
    balance,
    balancePts,
    credit,
    debit,
    referralCode,
    cpf,
    qtyGasStations,
    portabilityHasBeenDone,
    customer,
    profile,
    choiceProfile,
    clientReferrer,
    accountId,
  ];
}
