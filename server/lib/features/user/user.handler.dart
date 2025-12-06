import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:common/common.dart';
import 'user.repository.dart';

class UserHandler {
  final UserRepository _repository;

  UserHandler(this._repository);

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      AppLogger.func();
      try {
        final users = await _repository.getAllUsers();
        final usersJson = users.map((user) => user.toJson()).toList();
        return Response.ok(jsonEncode(usersJson), headers: {'Content-Type': 'application/json'});
      } catch (e, stack) {
        AppLogger.error(e, stack);
        return Response.internalServerError(body: 'Erro ao buscar usuários.');
      }
    });

    router.post('/', (Request request) async {
      AppLogger.func();
      try {
        final body = await request.readAsString();
        if (body.isEmpty) {
          return Response.badRequest(body: 'Corpo da requisição não pode ser vazio.');
        }

        final userMap = jsonDecode(body);
        final newUser = User.fromMap(userMap);
        final createdUser = await _repository.createUser(newUser);

        return Response(
          201, // 201 Created
          body: jsonEncode(createdUser.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e, stack) {
        AppLogger.error(e, stack);
        return Response.internalServerError(body: 'Erro ao criar usuário: ${e.toString()}');
      }
    });

    return router;
  }
}
