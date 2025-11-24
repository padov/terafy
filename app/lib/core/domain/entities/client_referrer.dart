import 'package:equatable/equatable.dart';

class ClientReferrer extends Equatable {
  final String id;
  final String name;
  final String? sexo;

  const ClientReferrer({required this.id, required this.name, this.sexo});

  @override
  List<Object?> get props => [id, name, sexo];
}
