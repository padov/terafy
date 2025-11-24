#!/bin/bash
# Script para limpar storage do app Android

echo "🔄 Limpando dados do app..."

# Para Android
adb shell pm clear com.example.terafy

if [ $? -eq 0 ]; then
    echo "✅ Storage limpo com sucesso!"
    echo "📱 Agora você pode executar o app novamente"
else
    echo "❌ Erro ao limpar storage"
    echo "💡 Alternativa: Desinstale o app manualmente"
fi

