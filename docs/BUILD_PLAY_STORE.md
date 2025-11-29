# Build para Google Play Store

## 🚀 Gerar o App Bundle (.aab)

### Opção 1: Usando o Makefile (Recomendado)

```bash
cd app
make build-bundle
```

### Opção 2: Comando Direto

```bash
cd app
flutter clean
flutter build appbundle --release
```

## 📦 Localização do Arquivo

Após o build, o arquivo `.aab` estará em:

```
app/build/app/outputs/bundle/release/app-release.aab
```

## ✅ Verificações Antes do Upload

1. **Verificar se o keystore está configurado:**
   ```bash
   cd app
   make check-keystore
   ```

2. **Verificar o tamanho do arquivo:**
   ```bash
   ls -lh app/build/app/outputs/bundle/release/app-release.aab
   ```

3. **Verificar a versão no pubspec.yaml:**
   - O arquivo `app/pubspec.yaml` deve ter a versão atualizada
   - Formato: `version: X.Y.Z+BUILD_NUMBER`
   - Exemplo: `version: 1.0.0+1`

## 📤 Upload na Play Store

1. Acesse o [Google Play Console](https://play.google.com/console)
2. Selecione seu app (ou crie um novo)
3. Vá em **Produção** (ou **Teste interno**)
4. Clique em **Criar nova versão**
5. Faça upload do arquivo `app-release.aab`
6. Preencha as informações da versão
7. Envie para revisão

## ⚠️ Importante

- ✅ O arquivo `.aab` é o formato correto para Play Store
- ✅ O app estará assinado com sua chave de release
- ✅ Faça backup do keystore e senhas antes de publicar
- ✅ Cada nova versão deve ter o `versionCode` incrementado

## 🔄 Para Nova Versão

Quando for fazer uma nova versão:

1. Atualize a versão no `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Incremente o número do build (+2, +3, etc.)
   ```

2. Execute o build novamente:
   ```bash
   cd app
   flutter clean
   make build-bundle
   ```

3. Faça upload do novo `.aab` na Play Store

