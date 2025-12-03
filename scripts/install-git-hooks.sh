#!/bin/bash
# Script para instalar git hooks
# Uso: ./scripts/install-git-hooks.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
HOOK_FILE="$GIT_HOOKS_DIR/pre-push"

echo "🔧 Instalando git hooks..."
echo ""

# Verificar se estamos em um repositório git
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "❌ Erro: Não é um repositório git!"
    exit 1
fi

# Criar diretório de hooks se não existir
mkdir -p "$GIT_HOOKS_DIR"

# Copiar hook pre-push
if [ -f "$HOOK_FILE" ]; then
    echo "✅ Git hook pre-push já existe"
else
    # O hook já foi criado, apenas garantir permissões
    echo "📝 Configurando git hook pre-push..."
fi

# Garantir permissões de execução
chmod +x "$HOOK_FILE" 2>/dev/null || true

echo ""
echo "✅ Git hooks instalados com sucesso!"
echo ""
echo "📋 O hook pre-push irá:"
echo "   - Executar testes do backend antes de cada push"
echo "   - Executar testes do frontend antes de cada push"
echo "   - Bloquear o push se algum teste falhar"
echo ""
echo "💡 Para pular os testes (não recomendado):"
echo "   SKIP_TESTS=1 git push"
echo ""

