# 🔧 Recriar Keystore - Solução Rápida

## ❌ Problema
Erro: "Failed to read key terafy from store... Given final block not properly padded"

Isso significa que as senhas no `key.properties` não correspondem ao keystore existente.

## ✅ Solução Rápida

### Opção 1: Comando Automático (Recomendado)

```bash
cd app
make recreate-keystore
```

Este comando vai:
1. Ler as senhas do `key.properties`
2. Remover o keystore antigo
3. Criar um novo keystore com as senhas corretas

### Opção 2: Manual (Se preferir controle total)

```bash
cd app/android/app

# 1. Remover keystore antigo
rm upload-keystore.jks

# 2. Criar novo com as senhas do key.properties
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias terafy \
  -storepass iKe3iuh86uZM4V7j \
  -keypass anMzxyBOzaLNBPwf \
  -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR"
```

## 🚀 Depois de Recriar

1. Limpar builds anteriores:
   ```bash
   cd app
   flutter clean
   ```

2. Gerar novo bundle:
   ```bash
   flutter build appbundle --release
   ```

## ⚠️ IMPORTANTE

**SÓ recrie o keystore se você:**
- ✅ Ainda NÃO publicou o app na Play Store
- ✅ Ou está criando um app completamente novo

**NÃO recrie se você:**
- ❌ Já publicou na Play Store
- ❌ Já tem usuários instalando o app

Nesses casos, você PRECISA encontrar as senhas corretas do keystore original.

