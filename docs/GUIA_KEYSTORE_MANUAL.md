# Guia Manual: Configuração de Keystore para Android

Este guia explica como configurar o keystore manualmente para assinar o app para publicação na Play Store.

## 📋 Passo a Passo Completo

### 1. Gerar o Keystore

Abra o terminal e execute:

```bash
cd app/android/app
```

Agora execute o comando para gerar o keystore. **Substitua as senhas** pelos seus valores:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias terafy \
  -storepass iKe3iuh86uZM4V7j \
  -keypass anMzxyBOzaLNBPwf \
  -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR"
```

**O que significa cada parte:**
- `-keystore upload-keystore.jks` → Nome do arquivo do keystore
- `-alias terafy` → Nome do alias (identificador da chave)
- `-storepass` → Senha do keystore
- `-keypass` → Senha da chave (pode ser igual à do keystore)
- `-validity 10000` → Válido por ~27 anos
- `-dname` → Dados da organização (pode personalizar)

**⚠️ IMPORTANTE:**
- Anote as senhas em local seguro (gerenciador de senhas)
- Escolha senhas fortes
- As senhas serão necessárias para TODAS as atualizações

### 2. Criar o arquivo `key.properties`

Volte para o diretório `app/android/`:

```bash
cd ..  # Agora está em app/android/
```

Crie o arquivo `key.properties`:

```bash
nano key.properties
```

Ou se preferir usar outro editor:
```bash
code key.properties  # VS Code
vim key.properties   # Vim
```

Adicione o seguinte conteúdo, **substituindo pelas suas senhas**:

```properties
storePassword=SUA_SENHA_KEYSTORE_AQUI
keyPassword=SUA_SENHA_CHAVE_AQUI
keyAlias=terafy
storeFile=upload-keystore.jks
```

**Exemplo:**
```properties
storePassword=MinhaSenh@SuperSegura123
keyPassword=MinhaSenh@SuperSegura123
keyAlias=terafy
storeFile=upload-keystore.jks
```

Salve o arquivo (Ctrl+O, Enter, Ctrl+X no nano).

### 3. Verificar a Estrutura de Arquivos

Verifique se os arquivos estão nos locais corretos:

```
app/
└── android/
    ├── key.properties              ← Arquivo de configuração
    └── app/
        └── upload-keystore.jks     ← Arquivo do keystore
```

Para verificar:

```bash
cd app/android
ls -la key.properties
ls -la app/upload-keystore.jks
```

Ambos os arquivos devem existir.

### 4. Verificar a Configuração do build.gradle.kts

O arquivo `app/android/app/build.gradle.kts` já deve estar configurado. Verifique se contém:

```kotlin
// Carrega as propriedades do keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

// ... no bloco signingConfigs
signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { 
                val storeFilePath = it
                val keystoreFile = if (file(storeFilePath).isAbsolute) {
                    file(storeFilePath)
                } else {
                    file("$projectDir/$storeFilePath")
                }
                keystoreFile
            }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}

// ... no bloco buildTypes
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists()) {
            signingConfigs.getByName("release")
        } else {
            signingConfigs.getByName("debug")
        }
    }
}
```

### 5. Testar a Configuração

Para testar se está tudo funcionando:

```bash
cd app
flutter clean
flutter build appbundle --release
```

Se tudo estiver correto, o build será criado em:
```
app/build/app/outputs/bundle/release/app-release.aab
```

### 6. Verificar a Assinatura (Opcional)

Você pode verificar se o keystore foi criado corretamente:

```bash
cd app/android/app
keytool -list -v -keystore upload-keystore.jks -alias terafy -storepass SUA_SENHA_KEYSTORE
```

Isso mostrará informações sobre o certificado.

## 🔒 Segurança

### ⚠️ IMPORTANTE - Faça Backup!

1. **Backup do keystore:**
   ```bash
   cp app/android/app/upload-keystore.jks ~/backup-seguro/upload-keystore.jks
   ```

2. **Backup do key.properties:**
   ```bash
   cp app/android/key.properties ~/backup-seguro/key.properties
   ```

3. **Salve as senhas** em um gerenciador de senhas seguro

4. **Armazene backups** em múltiplos lugares:
   - Pendrive criptografado
   - Cofre de senhas (LastPass, 1Password, etc.)
   - Cloud privado/criptografado

### ⚠️ NUNCA:
- ❌ Commit o keystore no Git
- ❌ Commit o `key.properties` no Git
- ❌ Compartilhe o keystore publicamente
- ❌ Perda as senhas

✅ Esses arquivos já estão no `.gitignore` para sua proteção.

## 🐛 Solução de Problemas

### Erro: "alias already exists"

Se você tentar criar o keystore novamente e receber este erro:

```
erro de keytool: java.lang.Exception: Par de chaves não gerado; o alias <terafy> já existe
```

**Solução:** O keystore já existe! Você tem duas opções:

1. **Usar o keystore existente** (recomendado):
   - Verifique se o arquivo `upload-keystore.jks` existe
   - Use as senhas que você configurou anteriormente
   - Configure apenas o `key.properties`

2. **Remover e recriar** (só se realmente necessário):
   ```bash
   rm app/android/app/upload-keystore.jks
   # Depois execute novamente o comando keytool
   ```

### Erro: "Cannot load key"

- Verifique se o `keyAlias` no `key.properties` está correto (deve ser `terafy`)
- Verifique se as senhas estão corretas (sem espaços extras)
- Verifique se o arquivo `upload-keystore.jks` existe no local correto

### Erro: "storeFile not found"

- Verifique se o caminho no `key.properties` está correto:
  - `storeFile=upload-keystore.jks` (caminho relativo ao diretório `app/`)
- Verifique se o arquivo existe em `app/android/app/upload-keystore.jks`

## 📝 Checklist Final

Antes de gerar o bundle para Play Store:

- [ ] Keystore criado em `app/android/app/upload-keystore.jks`
- [ ] Arquivo `key.properties` criado em `app/android/key.properties`
- [ ] Senhas corretas no `key.properties`
- [ ] Backup do keystore feito
- [ ] Backup das senhas feito
- [ ] Teste de build executado com sucesso
- [ ] Arquivo `.aab` gerado corretamente

## 🚀 Próximos Passos

Depois de configurar o keystore:

1. Gere o App Bundle:
   ```bash
   cd app
   flutter build appbundle --release
   ```

2. Encontre o arquivo em:
   ```
   app/build/app/outputs/bundle/release/app-release.aab
   ```

3. Faça upload do `.aab` na Play Store Console

## 📚 Referências

- [Flutter - Signing the app](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Android - Sign your app](https://developer.android.com/studio/publish/app-signing)

