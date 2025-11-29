#!/bin/bash

# Script para recriar o keystore com as senhas corretas do key.properties

set -e

echo "🔐 Recriando keystore para assinatura de release..."

# Verificar se estamos no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erro: Execute este script do diretório 'app'"
    exit 1
fi

# Ler senhas do key.properties
KEY_PROPERTIES_FILE="android/key.properties"
if [ ! -f "$KEY_PROPERTIES_FILE" ]; then
    echo "❌ Erro: Arquivo $KEY_PROPERTIES_FILE não encontrado"
    exit 1
fi

# Extrair senhas do key.properties
STORE_PASSWORD=$(grep "^storePassword=" "$KEY_PROPERTIES_FILE" | cut -d'=' -f2)
KEY_PASSWORD=$(grep "^keyPassword=" "$KEY_PROPERTIES_FILE" | cut -d'=' -f2)
KEY_ALIAS=$(grep "^keyAlias=" "$KEY_PROPERTIES_FILE" | cut -d'=' -f2)

if [ -z "$STORE_PASSWORD" ] || [ -z "$KEY_PASSWORD" ]; then
    echo "❌ Erro: Não foi possível ler as senhas do key.properties"
    exit 1
fi

echo "📋 Configuração:"
echo "   Alias: $KEY_ALIAS"
echo "   Store Password: [configurada]"
echo "   Key Password: [configurada]"
echo ""

# Remover keystore antigo se existir
KEYSTORE_PATH="android/app/upload-keystore.jks"
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Removendo keystore antigo..."
    rm "$KEYSTORE_PATH"
    echo "✅ Keystore antigo removido"
    echo ""
fi

# Criar diretório se não existir
mkdir -p android/app

# Criar novo keystore
echo "🔑 Criando novo keystore..."
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Terafy, OU=Mobile, O=Terafy, L=SaoPaulo, ST=SP, C=BR"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore criado com sucesso em: $KEYSTORE_PATH"
    echo ""
    echo "📝 Verificando configuração..."
    if [ -f "$KEY_PROPERTIES_FILE" ] && [ -f "$KEYSTORE_PATH" ]; then
        echo "✅ key.properties existe"
        echo "✅ Keystore existe"
        echo ""
        echo "🚀 Pronto para fazer o build!"
        echo "   Execute: flutter clean && flutter build appbundle --release"
    else
        echo "⚠️  Verificação falhou"
        exit 1
    fi
else
    echo "❌ Erro ao criar keystore"
    exit 1
fi

