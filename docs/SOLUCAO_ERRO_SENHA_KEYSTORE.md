# Solução: Erro de Senha do Keystore

## ❌ Erro Encontrado

```
Failed to read key terafy from store ".../upload-keystore.jks": 
Get Key failed: Given final block not properly padded. 
Such issues can arise if a bad key is used during decryption.
```

## 🔍 Problema

As senhas no arquivo `key.properties` não correspondem às senhas reais do keystore existente.

## ✅ Soluções

### Opção 1: Corrigir as Senhas no key.properties (Se você sabe as senhas corretas)

Edite o arquivo `app/android/key.properties` e coloque as senhas corretas:

```properties
storePassword=SENHA_CORRETA_DO_KEYSTORE
keyPassword=SENHA_CORRETA_DA_CHAVE
keyAlias=terafy
storeFile=upload-keystore.jks
```

### Opção 2: Verificar as Senhas do Keystore

Você pode tentar verificar se as senhas estão corretas:

```bash
cd app/android/app
keytool -list -v -keystore upload-keystore.jks -alias terafy
```

Ele vai pedir a senha. Se funcionar, as senhas estão corretas. Se não funcionar, as senhas estão erradas.

### Opção 3: Recriar o Keystore (Se você não tem as senhas)

⚠️ **ATENÇÃO**: Só faça isso se você **NÃO JÁ PUBLICOU** o app na Play Store. Se já publicou, você **NÃO PODE** recriar o keystore.

1. **Remover o keystore antigo:**
   ```bash
   cd app/android/app
   rm upload-keystore.jks
   ```

2. **Criar novo keystore com as senhas que estão no key.properties:**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias terafy \
     -storepass iKe3iuh86uZM4V7j \
     -keypass anMzxyBOzaLNBPwf \
     -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR"
   ```

3. **Verificar se o key.properties está correto:**
   O arquivo `app/android/key.properties` deve ter:
   ```properties
   storePassword=iKe3iuh86uZM4V7j
   keyPassword=anMzxyBOzaLNBPwf
   keyAlias=terafy
   storeFile=upload-keystore.jks
   ```

4. **Testar o build:**
   ```bash
   cd app
   flutter clean
   flutter build appbundle --release
   ```

## 🚨 Importante

- Se você **já publicou** na Play Store com o keystore antigo, **NÃO** pode recriar. Você precisa encontrar as senhas corretas.
- Faça backup das senhas em local seguro.
- Nunca compartilhe as senhas publicamente.

