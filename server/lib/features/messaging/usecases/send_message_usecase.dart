import 'package:server/features/messaging/domain/message.dart';
import 'package:server/features/messaging/domain/message_provider.dart';
import 'package:server/features/messaging/domain/message_repository.dart';
import 'package:server/features/messaging/domain/message_channel.dart';
import 'package:common/common.dart';

/// UseCase para envio genérico de mensagens
class SendMessageUseCase {
  final MessageRepository _repository;
  final Map<MessageChannel, MessageProvider> _providers;

  SendMessageUseCase(
    this._repository,
    this._providers,
  );

  /// Envia uma mensagem usando o provider apropriado
  Future<Message> execute(Message message) async {
    AppLogger.func();

    // Obtém o provider para o canal da mensagem
    final provider = _providers[message.channel];
    if (provider == null) {
      throw Exception('Provider não encontrado para o canal ${message.channel.name}');
    }

    // Valida a mensagem
    final validationErrors = await provider.validate(message);
    if (validationErrors.isNotEmpty) {
      throw Exception('Erro de validação: ${validationErrors.join('; ')}');
    }

    // Cria a mensagem no banco com status pending
    final createdMessage = await _repository.create(
      message.copyWith(
        status: MessageStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    try {
      // Envia a mensagem
      final result = await provider.send(createdMessage);

      if (result.success) {
        // Atualiza status para sent
        return await _repository.updateStatus(
          createdMessage.id!,
          MessageStatus.sent,
          sentAt: DateTime.now(),
        );
      } else {
        // Atualiza status para failed
        return await _repository.updateStatus(
          createdMessage.id!,
          MessageStatus.failed,
          errorMessage: result.errorMessage,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
      // Atualiza status para failed
      return await _repository.updateStatus(
        createdMessage.id!,
        MessageStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
}

