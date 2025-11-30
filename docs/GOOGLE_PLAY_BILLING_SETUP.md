# Configuração de Assinaturas no Google Play Console

Este documento descreve o processo de configuração de produtos de assinatura no Google Play Console para o app Terafy.

## Pré-requisitos

1. Conta de desenvolvedor no Google Play Console
2. App publicado ou em teste interno/fechado
3. Acesso ao Google Play Console com permissões de administrador

## Passo a Passo

### 1. Acessar o Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione seu app (Terafy)
3. No menu lateral, vá em **Monetização** > **Produtos** > **Assinaturas**

### 2. Criar Produto de Assinatura

1. Clique em **Criar assinatura**
2. Preencha os seguintes campos:

#### Informações Básicas

- **ID do produto**: `starter_monthly`
  - Este ID deve corresponder ao campo `play_store_product_id` na tabela `plans` do banco de dados
- **Nome**: `Starter`
- **Descrição**: `Plano Starter com limite ampliado de pacientes`

#### Preço e Período

- **Período de cobrança**: Mensal
- **Preço**: R$ 30,00
- **Período de teste gratuito** (opcional): Configure se desejar oferecer período de teste
- **Período de graça** (opcional): Configure se desejar oferecer período de graça após o pagamento falhar

#### Configurações Adicionais

- **Renovação automática**: Ativada
- **Cancelamento**: Permitir cancelamento a qualquer momento
- **Reembolso**: Configurar conforme política da loja

### 3. Configurar Preços por País

1. Na página do produto, vá em **Preços**
2. Configure preços para diferentes países se necessário
3. Para o Brasil, mantenha R$ 30,00

### 4. Ativar o Produto

1. Após criar o produto, certifique-se de que ele está **Ativo**
2. O status deve aparecer como "Ativo" na lista de produtos

### 5. Configurar no Banco de Dados

Após criar o produto no Play Console, atualize o banco de dados:

```sql
UPDATE plans 
SET play_store_product_id = 'starter_monthly'
WHERE name = 'Starter';
```

### 6. Testar a Assinatura

#### Contas de Teste

1. No Google Play Console, vá em **Configurações** > **Acesso à licença**
2. Adicione contas de teste do Gmail
3. Essas contas poderão testar assinaturas sem serem cobradas

#### Teste no App

1. Instale o app em um dispositivo Android
2. Faça login com uma conta de teste
3. Navegue até a página de assinaturas
4. Tente comprar o plano Starter
5. Verifique se a compra é processada corretamente

### 7. Verificar Assinaturas Ativas

No Google Play Console, você pode verificar assinaturas ativas em:
- **Monetização** > **Assinaturas** > **Assinantes ativos**

## Estrutura de Planos

### Plano Free

- **ID do produto**: Não possui (plano gratuito)
- **Limite de pacientes**: 10
- **Preço**: R$ 0,00
- **Status**: Sempre ativo (padrão)

### Plano Starter

- **ID do produto**: `starter_monthly`
- **Limite de pacientes**: 999.999 (praticamente ilimitado)
- **Preço**: R$ 30,00/mês
- **Período**: Mensal

## Notas Importantes

1. **Product ID**: O `play_store_product_id` no banco de dados deve corresponder exatamente ao ID do produto no Play Console
2. **Preços**: Os preços devem ser configurados no Play Console. O preço no banco de dados é apenas informativo
3. **Testes**: Use sempre contas de teste durante o desenvolvimento
4. **Verificação**: O backend verifica todas as compras com o Google Play para segurança
5. **Renovação**: As renovações automáticas são gerenciadas pelo Google Play

## Troubleshooting

### Produto não aparece no app

- Verifique se o `play_store_product_id` no banco corresponde ao ID no Play Console
- Certifique-se de que o produto está ativo no Play Console
- Verifique se o app está publicado ou em teste interno

### Compra não é processada

- Verifique se está usando uma conta de teste
- Verifique os logs do app para erros
- Verifique se o backend está recebendo e processando a verificação corretamente

### Assinatura não renova

- Verifique se a renovação automática está ativada no Play Console
- Verifique se o pagamento está sendo processado corretamente
- Verifique os logs do backend para erros na sincronização

## Referências

- [Documentação do Google Play Billing](https://developer.android.com/google/play/billing)
- [Guia de Assinaturas](https://developer.android.com/google/play/billing/subscriptions)
- [Teste de Assinaturas](https://developer.android.com/google/play/billing/test)

