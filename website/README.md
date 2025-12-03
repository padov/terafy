# Website Institucional Terafy

Página institucional moderna e responsiva do Terafy, criada com HTML, CSS e JavaScript vanilla.

## 🎨 Design

- **Paleta de cores**: Baseada na identidade visual Terafy (azul/teal)
- **Tipografia**: Nunito Sans (padrão) e Rubik (destaques)
- **Estilo**: Moderno, premium, com gradientes e animações suaves
- **Responsivo**: Desktop, tablet e mobile

## 📁 Estrutura

```
website/
├── index.html          # Página principal
├── privacy.html        # Política de privacidade
├── style.css           # Estilos (design system completo)
├── script.js           # Interatividade e animações
├── version.json        # Controle de versão
└── assets/
    └── images/
        └── logo.png    # Logo do Terafy
```

## 🚀 Como Testar Localmente

### Opção 1: Python (recomendado)

```bash
cd website
python3 -m http.server 8000
```

Acesse: http://localhost:8000

### Opção 2: Node.js (npx)

```bash
cd website
npx http-server -p 8000
```

Acesse: http://localhost:8000

### Opção 3: VS Code Live Server

1. Instale a extensão "Live Server"
2. Clique com botão direito em `index.html`
3. Selecione "Open with Live Server"

## 🌐 Deploy em Produção

O website é automaticamente incluído no processo de deploy:

```bash
cd deploy
./prepare-deploy.sh [VM_NAME]
```

O Nginx servirá os arquivos em:

- **Produção**: https://www.terafy.app.br
- **Localização**: `/usr/share/nginx/html/www`

## ✨ Funcionalidades

### Seções

- **Hero**: Apresentação principal com estatísticas animadas
- **Funcionalidades**: 8 cards com principais recursos do sistema
- **Benefícios**: 4 benefícios numerados
- **Planos**: 3 opções de planos (Gratuito, Profissional, Premium)
- **Contato**: Formulário e informações de contato

### Interatividade

- Menu mobile responsivo com animação
- Scroll suave entre seções
- Animações on scroll (fade-in)
- Contador animado para estatísticas
- Hover effects em cards e botões
- Floating cards no hero
- Formulário de contato com validação

## 🎯 SEO

- Meta tags completas (title, description, keywords)
- Estrutura semântica HTML5
- Heading hierarchy apropriada
- IDs únicos para navegação
- Performance otimizada

## 📱 Responsividade

### Breakpoints

- **Desktop**: > 1024px
- **Tablet**: 768px - 1024px
- **Mobile**: < 768px

### Adaptações Mobile

- Menu hamburguer
- Layout vertical
- Cards em coluna única
- Botões full-width
- Espaçamentos reduzidos

## 🎨 Paleta de Cores

| Cor            | Hex       | Uso                      |
| -------------- | --------- | ------------------------ |
| Primary Blue   | `#0891B2` | Botões, links, destaques |
| Primary Teal   | `#14B8A6` | Gradientes, hover        |
| Primary Dark   | `#085878` | Backgrounds escuros      |
| Gray 900       | `#111827` | Textos principais        |
| Gray 50        | `#F9FAFB` | Backgrounds claros       |

## 🔧 Customização

### Alterar Cores

Edite as variáveis CSS em `style.css`:

```css
:root {
  --primary-blue: #0891B2;
  --primary-teal: #14B8A6;
  --primary-blue-dark: #085878;
  /* ... outras cores */
}
```

### Alterar Conteúdo

Edite diretamente o `index.html`. Todas as seções estão bem comentadas.

### Adicionar Páginas

1. Crie novo arquivo HTML (ex: `sobre.html`)
2. Copie a estrutura de `index.html`
3. Atualize os links de navegação

## 📊 Performance

- **Gzip**: Habilitado no Nginx
- **Cache**: Assets com cache de 1 ano
- **Lazy Loading**: Imagens carregadas sob demanda
- **Debounce**: Eventos de scroll otimizados
- **Minificação**: Recomendado para produção

## 🔒 Segurança

Headers configurados no Nginx:

- `Strict-Transport-Security`
- `X-Frame-Options`
- `X-Content-Type-Options`
- `X-XSS-Protection`

## 📦 Controle de Versão

O website possui controle de versão através do arquivo `version.json`:

```json
{
  "version": "0.1.0",
  "build": 1,
  "releaseDate": "2024-01-01"
}
```

A versão é exibida automaticamente no footer do site. Para atualizar:

1. Edite `version.json` com a nova versão
2. A versão será carregada automaticamente na página

**Formato de versão**: Segue SemVer (MAJOR.MINOR.PATCH)

## 📝 Próximas Melhorias

- [ ] Integrar formulário com backend
- [ ] Adicionar Google Analytics
- [ ] Implementar dark mode
- [ ] Adicionar mais páginas (blog, sobre)
- [ ] Otimizar imagens (WebP)
- [ ] Adicionar testes E2E

## 🤝 Contribuindo

Para fazer alterações:

1. Edite os arquivos localmente
2. Teste com servidor local
3. Commit e push
4. Execute `./deploy/prepare-deploy.sh` para deploy

---

**Desenvolvido com ❤️ para Terafy**
