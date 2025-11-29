# Configuração de Assinatura (Keystore) para Android

## ⚠️ IMPORTANTE

**Você DEVE configurar o keystore ANTES de publicar na Play Store!**

- A Play Store **exige** assinatura para todos os apps
- Uma vez publicado, **todas as atualizações** devem usar a **mesma chave**
- Se perder a chave, **não conseguirá mais atualizar** o app na Play Store
- **Faça backup** seguro do keystore e das senhas!

## 📋 Passo a Passo

### Opção 1: Setup Interativo (Recomendado)

```bash
cd app
make setup-keystore
```

Este comando irá:
1. Solicitar as senhas (keystore e key)
2. Gerar o keystore automaticamente
3. Criar o arquivo `android/key.properties`

### Opção 2: Setup Manual

#### 1. Gerar o Keystore

```bash
cd app
make create-keystore KEYSTORE_PASSWORD=sua_senha KEY_PASSWORD=sua_senha
```

Ou manualmente:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias terafy \
  -storepass SUA_SENHA_KEYSTORE \
  -keypass SUA_SENHA_CHAVE \
  -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR"
```

#### 2. Criar o arquivo `android/key.properties`

```bash
cp android/key.properties.example android/key.properties
```

Edite `android/key.properties` e preencha com suas senhas:

```properties
storePassword=SUA_SENHA_DO_KEYSTORE
keyPassword=SUA_SENHA_DA_CHAVE
keyAlias=terafy
storeFile=upload-keystore.jks
```

### 3. Verificar Configuração

```bash
cd app
make check-keystore
```

### 4. Gerar o App Bundle para Play Store

```bash
cd app
make build-bundle
```

O arquivo `.aab` será gerado em:
```
app/build/app/outputs/bundle/release/app-release.aab
```

## 🔒 Segurança

- ✅ O arquivo `key.properties` e `*.jks` estão no `.gitignore` (não serão commitados)
- ✅ **NUNCA** compartilhe o keystore publicamente
- ✅ Faça backup seguro em múltiplos lugares (cofre, pendrive criptografado, etc.)
- ✅ Salve as senhas em um gerenciador de senhas seguro

## 📝 Informações sobre o Keystore

- **Arquivo**: `android/app/upload-keystore.jks`
- **Alias**: `terafy`
- **Algoritmo**: RSA 2048 bits
- **Validade**: 10000 dias (~27 anos)

## 🚨 Problemas Comuns

### "Keystore file not found"
- Verifique se o arquivo existe em `android/app/upload-keystore.jks`
- Verifique o caminho no `key.properties` está correto

### "Password was incorrect"
- Verifique as senhas no `key.properties`
- Certifique-se de que não há espaços extras

### "Cannot load key"
- Verifique se o `keyAlias` está correto (deve ser `terafy`)
- Tente recriar o keystore se necessário

## 📚 Referências

- [Flutter - Signing the app](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Android - Sign your app](https://developer.android.com/studio/publish/app-signing)

