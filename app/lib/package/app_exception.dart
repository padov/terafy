// ignore_for_file: public_member_api_docs, sort_constructors_first
class AppException implements Exception {
  String? service;
  final String message;
  AppException({this.service, required this.message});

  @override
  String toString() {
    return '[$service] - $message';
  }
}
