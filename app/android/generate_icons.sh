#!/bin/bash

# Script para gerar os ícones do Android em todos os tamanhos necessários
# Execute este script a partir da pasta app/android

SOURCE_ICON="../../assets/images/icon.png"
RES_DIR="app/src/main/res"

echo "Gerando ícones do Android..."

# Verificar se o arquivo fonte existe
if [ ! -f "$SOURCE_ICON" ]; then
    echo "❌ Erro: Arquivo $SOURCE_ICON não encontrado!"
    exit 1
fi

# Verificar se o ImageMagick está instalado
if ! command -v convert &> /dev/null; then
    echo "❌ Erro: ImageMagick não está instalado!"
    echo "Instale com: brew install imagemagick"
    exit 1
fi

# Gerar os ícones em todos os tamanhos
echo "📱 Gerando ícone para mipmap-mdpi (48x48)..."
convert "$SOURCE_ICON" -resize 48x48 "$RES_DIR/mipmap-mdpi/ic_launcher.png"

echo "📱 Gerando ícone para mipmap-hdpi (72x72)..."
convert "$SOURCE_ICON" -resize 72x72 "$RES_DIR/mipmap-hdpi/ic_launcher.png"

echo "📱 Gerando ícone para mipmap-xhdpi (96x96)..."
convert "$SOURCE_ICON" -resize 96x96 "$RES_DIR/mipmap-xhdpi/ic_launcher.png"

echo "📱 Gerando ícone para mipmap-xxhdpi (144x144)..."
convert "$SOURCE_ICON" -resize 144x144 "$RES_DIR/mipmap-xxhdpi/ic_launcher.png"

echo "📱 Gerando ícone para mipmap-xxxhdpi (192x192)..."
convert "$SOURCE_ICON" -resize 192x192 "$RES_DIR/mipmap-xxxhdpi/ic_launcher.png"

echo "✅ Ícones gerados com sucesso!"
echo ""
echo "Agora você pode fazer rebuild do app para ver os novos ícones."

