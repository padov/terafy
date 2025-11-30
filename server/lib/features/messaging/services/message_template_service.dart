import 'package:server/features/messaging/domain/message_template.dart';

/// Resultado do processamento de template
class ProcessedTemplate {
  final String subject;
  final String content;

  const ProcessedTemplate({
    required this.subject,
    required this.content,
  });
}

/// Serviço para processar templates de mensagens
class MessageTemplateService {
  /// Processa um template substituindo variáveis pelos valores fornecidos
  ProcessedTemplate processTemplate(
    MessageTemplate template,
    Map<String, dynamic> variables,
  ) {
    final subject = _replaceVariables(template.subjectTemplate, variables);
    final content = _replaceVariables(template.contentTemplate, variables);

    return ProcessedTemplate(
      subject: subject,
      content: content,
    );
  }

  /// Substitui variáveis no formato {variavel} pelos valores do mapa
  String _replaceVariables(String template, Map<String, dynamic> variables) {
    String result = template;

    // Substitui cada variável encontrada
    variables.forEach((key, value) {
      final placeholder = '{${key}}';
      final replacement = _formatValue(value);
      result = result.replaceAll(placeholder, replacement);
    });

    return result;
  }

  /// Formata um valor para string
  String _formatValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      // Formata data/hora em português brasileiro
      return _formatDateTime(value);
    }

    if (value is Duration) {
      // Formata duração
      return _formatDuration(value);
    }

    return value.toString();
  }

  /// Formata DateTime em formato brasileiro
  String _formatDateTime(DateTime dateTime) {
    final days = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado'
    ];
    final months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];

    final dayName = days[dateTime.weekday % 7];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$dayName, $day de $month de $year às $hour:$minute';
  }

  /// Formata Duration em formato legível
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'dia' : 'dias'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'segundo' : 'segundos'}';
    }
  }

  /// Valida se todas as variáveis necessárias estão presentes
  List<String> validateVariables(
    MessageTemplate template,
    Map<String, dynamic> variables,
  ) {
    final missing = <String>[];

    // Extrai variáveis do template
    final requiredVars = _extractVariables(template.subjectTemplate) +
        _extractVariables(template.contentTemplate);

    // Remove duplicatas
    final uniqueVars = requiredVars.toSet();

    // Verifica quais estão faltando
    for (final varName in uniqueVars) {
      if (!variables.containsKey(varName)) {
        missing.add(varName);
      }
    }

    return missing;
  }

  /// Extrai todas as variáveis de um template (formato {variavel})
  List<String> _extractVariables(String template) {
    final regex = RegExp(r'\{([^}]+)\}');
    final matches = regex.allMatches(template);
    return matches.map((match) => match.group(1)!).toList();
  }
}

