import 'package:hotreloader/hotreloader.dart';
import 'server.dart' as server;

void main(List<String> args) async {
  // O HotReloader irá monitorar o código-fonte por mudanças
  // e reiniciar o servidor automaticamente.
  await HotReloader.create(
    onAfterReload: (event) {
      print('Recarregamento completo devido à mudança em: $event');
    },
    // Nós passamos a função main do nosso servidor principal aqui.
    // É importante passar os argumentos para ela.
    onBeforeReload: (event) {
      print('Mudança detectada em $event. Recarregando servidor...');
      return true;
    },
  );

  // Inicia o servidor pela primeira vez.
  server.main();
}
