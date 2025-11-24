import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? whatsapp;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.whatsapp,
  });

  @override
  List<Object?> get props => [id, name, phone, whatsapp];
}
