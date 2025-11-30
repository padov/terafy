# Resumo: Configuração na Play Store

## Sim, você precisa criar os produtos de assinatura na Play Store!

Para que o sistema de assinaturas funcione, você **precisa** criar os produtos de assinatura no Google Play Console. O app não funcionará sem isso.

## O que fazer:

### 1. Acessar Google Play Console
- Acesse: https://play.google.com/console
- Selecione seu app Terafy

### 2. Criar Produto de Assinatura
- Vá em **Monetização** > **Produtos** > **Assinaturas**
- Clique em **Criar assinatura**
- Configure:
  - **ID do produto**: `starter_monthly` (IMPORTANTE: deve ser exatamente este ID)
  - **Nome**: `Starter`
  - **Preço**: R$ 30,00/mês
  - **Período**: Mensal
  - **Renovação automática**: Ativada

### 3. Ativar o Produto
- Após criar, certifique-se de que está **Ativo**

### 4. Configurar no Banco de Dados
Após criar no Play Console, execute no banco:

```sql
UPDATE plans 
SET play_store_product_id = 'starter_monthly'
WHERE name = 'Starter';
```

## Importante:

1. **O app precisa estar publicado ou em teste interno** para criar produtos
2. **O ID do produto** (`starter_monthly`) deve ser exatamente igual no Play Console e no banco de dados
3. **Use contas de teste** durante desenvolvimento (configure em Configurações > Acesso à licença)

## Documentação Completa

Veja o guia completo em: `docs/GOOGLE_PLAY_BILLING_SETUP.md`

## Testando

1. Adicione contas de teste no Play Console
2. Instale o app em um dispositivo Android
3. Faça login com conta de teste
4. Navegue até a página de assinaturas
5. Tente comprar o plano Starter

## Status Atual

- ✅ Backend implementado e pronto
- ✅ App implementado e pronto
- ✅ Testes criados
- ⚠️ **FALTA**: Criar produtos no Play Console (você precisa fazer isso)

