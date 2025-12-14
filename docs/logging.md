# Sistema de Logging do Servidor

## 📋 Visão Geral

O sistema de logging do servidor Terafy oferece funcionalidades avançadas de registro de logs com suporte a:

- ✅ Log em arquivo (apenas servidor)
- ✅ Rotação automática por data e tamanho
- ✅ Compressão automática de logs rotacionados (gzip)
- ✅ Limpeza automática de logs antigos
- ✅ Configuração via variáveis de ambiente
- ✅ Níveis de log configuráveis

## 🔧 Configuração

### Variáveis de Ambiente

Configure o sistema de logging através do arquivo `.env`:

```env
# Nível de log (ALL, FINEST, FINE, INFO, WARNING, SEVERE, OFF)
LOG_LEVEL=ALL

# Habilita log em arquivo
LOG_TO_FILE=true

# Diretório de logs
LOG_DIR=./log

# Tamanho máximo do arquivo antes da rotação (em MB)
LOG_MAX_FILE_SIZE_MB=20

# Dias de retenção antes da limpeza automática
LOG_RETENTION_DAYS=30

# Comprime logs rotacionados com gzip
LOG_COMPRESS_ROTATED=true
```

### Níveis de Log

| Nível     | Descrição             | Uso Recomendado            |
| --------- | --------------------- | -------------------------- |
| `ALL`     | Todos os logs         | Desenvolvimento            |
| `FINEST`  | Debug muito detalhado | Debugging profundo         |
| `FINE`    | Debug                 | Rastreamento de funções    |
| `INFO`    | Informações gerais    | Produção (padrão)          |
| `WARNING` | Avisos                | Problemas não críticos     |
| `SEVERE`  | Erros graves          | Erros críticos             |
| `OFF`     | Desabilitado          | Quando não precisa de logs |

## 📁 Estrutura de Arquivos

Os logs são organizados da seguinte forma:

```
server/log/
├── app_2025-12-08.log          # Arquivo do dia atual
├── app_2025-12-08_1.log.gz     # Rotacionado por tamanho (comprimido)
├── app_2025-12-08_2.log.gz     # Segundo arquivo rotacionado
├── app_2025-12-07.log.gz       # Dia anterior (comprimido)
└── app_2025-12-06.log.gz       # Dois dias atrás (comprimido)
```

### Nomenclatura

- **Arquivo atual**: `app_YYYY-MM-DD.log`
- **Rotacionado por tamanho**: `app_YYYY-MM-DD_N.log.gz` (onde N é o contador)
- **Dia anterior**: `app_YYYY-MM-DD.log.gz`

## 🔄 Rotação de Logs

### Por Data

- Novo arquivo criado automaticamente a cada dia (00:00)
- Arquivo do dia anterior é comprimido (se `LOG_COMPRESS_ROTATED=true`)

### Por Tamanho

- Quando o arquivo atinge o tamanho máximo (`LOG_MAX_FILE_SIZE_MB`)
- Arquivo atual é comprimido e um novo é criado
- Sufixo numérico é adicionado (`_1`, `_2`, etc.)

## 🗑️ Limpeza Automática

Logs mais antigos que `LOG_RETENTION_DAYS` são deletados automaticamente:

- Verificação executada ao mudar de dia
- Aplica-se a arquivos `.log` e `.log.gz`
- Mensagem no console quando logs são removidos

**Exemplo**: Com `LOG_RETENTION_DAYS=30`, logs de 31 dias atrás ou mais são deletados.

## 📦 Compressão

### Quando Ocorre

- Ao rotacionar por tamanho
- Ao mudar de dia (arquivo do dia anterior)

### Formato

- Compressão: **gzip**
- Extensão: `.log.gz`
- Taxa de compressão: ~90% (logs de texto comprimem muito bem)

### Descompressão

Para ler um log comprimido:

```bash
# Ver conteúdo
gunzip -c server/log/app_2025-12-07.log.gz

# Ou descomprimir permanentemente
gunzip server/log/app_2025-12-07.log.gz
```

## 💻 Uso no Código

### Inicialização (Automática)

O logger é configurado automaticamente no `server.dart`:

```dart
AppLogger.config(
  isDebugMode: true,
  logToFile: EnvConfig.getOrDefault('LOG_TO_FILE', 'false') == 'true',
  logDirectory: EnvConfig.getOrDefault('LOG_DIR', './log'),
  logLevel: _parseLogLevel(EnvConfig.getOrDefault('LOG_LEVEL', 'ALL')),
  maxFileSizeMB: EnvConfig.getIntOrDefault('LOG_MAX_FILE_SIZE_MB', 20),
  retentionDays: EnvConfig.getIntOrDefault('LOG_RETENTION_DAYS', 30),
  compressRotated: EnvConfig.getOrDefault('LOG_COMPRESS_ROTATED', 'true') == 'true',
);
```

### Registrando Logs

```dart
// Informação
AppLogger.info('Usuário autenticado com sucesso');

// Aviso
AppLogger.warning('Taxa de requisições alta');

// Erro
AppLogger.error('Falha ao conectar ao banco de dados', stackTrace);

// Debug
AppLogger.debug('Valor da variável: $value');

// Rastreamento de função
AppLogger.func(name: 'processarPagamento');
```

## 🎯 Configurações Recomendadas

### Desenvolvimento

```env
LOG_LEVEL=ALL
LOG_TO_FILE=true
LOG_MAX_FILE_SIZE_MB=10
LOG_RETENTION_DAYS=7
LOG_COMPRESS_ROTATED=false  # Mais rápido sem compressão
```

### Testes

```env
LOG_LEVEL=WARNING
LOG_TO_FILE=false  # Apenas console
LOG_RETENTION_DAYS=1
LOG_COMPRESS_ROTATED=false
```

### Produção

```env
LOG_LEVEL=INFO
LOG_TO_FILE=true
LOG_MAX_FILE_SIZE_MB=50
LOG_RETENTION_DAYS=90
LOG_COMPRESS_ROTATED=true
```

## 🔍 Monitoramento

### Verificar Logs em Tempo Real

```bash
# Seguir logs do dia atual
tail -f server/log/app_$(date +%Y-%m-%d).log

# Últimas 100 linhas
tail -n 100 server/log/app_$(date +%Y-%m-%d).log
```

### Buscar Erros

```bash
# Buscar erros no log atual
grep "SEVERE" server/log/app_$(date +%Y-%m-%d).log

# Buscar em logs comprimidos
zgrep "SEVERE" server/log/app_*.log.gz
```

### Espaço em Disco

```bash
# Ver tamanho dos logs
du -sh server/log/

# Listar arquivos por tamanho
ls -lhS server/log/
```

## ⚠️ Considerações Importantes

### Performance

- Compressão é executada de forma síncrona (pode causar pequeno delay na rotação)
- Limpeza é executada apenas ao mudar de dia (impacto mínimo)
- Escrita em arquivo é thread-safe

### Espaço em Disco

Com as configurações padrão:

- Arquivo máximo: 20MB
- Retenção: 30 dias
- Espaço máximo estimado: ~600MB (sem compressão) ou ~60MB (com compressão)

### Backup

Logs comprimidos podem ser facilmente copiados para backup:

```bash
# Copiar logs antigos para backup
cp server/log/*.log.gz /backup/logs/
```

## 🐛 Troubleshooting

### Logs não estão sendo criados

1. Verifique se `LOG_TO_FILE=true` no `.env`
2. Verifique permissões do diretório `log/`
3. Verifique se há erros no console do servidor

### Arquivos não estão sendo comprimidos

1. Verifique se `LOG_COMPRESS_ROTATED=true`
2. Aguarde uma rotação (mudança de dia ou atingir tamanho máximo)
3. Verifique mensagens de erro no console

### Logs antigos não estão sendo deletados

1. Verifique `LOG_RETENTION_DAYS` no `.env`
2. Limpeza ocorre apenas ao mudar de dia
3. Verifique se as datas dos arquivos estão corretas

## 📚 Referências

- [Pacote logging (Dart)](https://pub.dev/packages/logging)
- [Compressão gzip (Dart)](https://api.dart.dev/stable/dart-io/gzip-constant.html)
- [Documentação do projeto](../README.md)
