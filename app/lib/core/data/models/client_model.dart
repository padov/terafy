import 'package:terafy/core/domain/entities/client.dart';

class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.name,
    required super.email,
    super.economized,
    super.phone,
    super.sexo,
    super.birthday,
    super.balance,
    super.balancePts,
    super.credit,
    super.debit,
    super.referralCode,
    super.cpf,
    super.qtyGasStations,
    super.portabilityHasBeenDone,
    super.accountId,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      economized: (json['economized'] as num?)?.toDouble(),
      phone: json['phone'],
      sexo: json['sexo'],
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'])
          : null,
      balance: (json['balance'] as num?)?.toDouble(),
      balancePts: (json['balancePts'] as num?)?.toDouble(),
      credit: (json['credit'] as num?)?.toDouble(),
      debit: (json['debit'] as num?)?.toDouble(),
      referralCode: json['referralCode'],
      cpf: json['cpf'],
      qtyGasStations: json['qtyGasStations'],
      portabilityHasBeenDone: json['portabilityHasBeenDone'],
    );
  }
}
