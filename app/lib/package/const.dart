enum Api { portal, cashback }

enum TipoAtendimento { abastecimento, produto, resgate }

enum TipoItem { product, productgas }

extension exTipoItem on TipoItem {
  String get denominacao {
    switch (this) {
      case TipoItem.product:
        return 'Produto';
      case TipoItem.productgas:
        return 'Abastecimento';
    }
  }

  String get key {
    switch (this) {
      case TipoItem.product:
        return 'product';
      case TipoItem.productgas:
        return 'productgas';
    }
  }
}

const uriValidaResgate = 'cashback-proprio/resgate/validar';
const uriProcessaResgate = 'cashback-proprio/resgate/processar';
const uriCancelaTransacao = 'cashback-proprio/cancelar-transacao';

const List<String> motivosEstorno = [
  'Cliente errado',
  'Abastecimento errado',
  'Forma de pagamento errada',
  'Solicitação do cliente',
  'Processo administrativo',
  'Outros',
];
