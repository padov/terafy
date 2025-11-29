# 🌐 Resumo da Configuração DNS

## 📊 Mapeamento de Domínios

```
┌─────────────────────────┬──────────┬─────────────────────────────┐
│ Domínio                 │ Porta    │ Destino                     │
├─────────────────────────┼──────────┼─────────────────────────────┤
│ www.terafy.app.br       │ 80       │ Flutter Web (estático)      │
│ terafy.app.br           │ 80       │ Flutter Web (estático)      │
│ app.terafy.app.br       │ 80       │ Flutter Web (estático)      │
│ api.terafy.app.br       │ 8080     │ API Backend (proxy)         │
└─────────────────────────┴──────────┴─────────────────────────────┘
```

## 🔄 Fluxo de Requisições

### API (api.terafy.app.br)
```
Cliente → Nginx:80 → Proxy → Servidor Dart:8080
```

### Flutter Web (www, terafy, app)
```
Cliente → Nginx:80 → Arquivos Estáticos (/usr/share/nginx/html)
```

## 📝 Registros DNS Necessários (registro.br)

Todos os registros apontam para o **mesmo IP estático**:

| Tipo | Nome | Valor (IP) | TTL |
|------|------|------------|-----|
| A | `@` | `34.29.65.82` | 3600 |
| A | `www` | `34.29.65.82` | 3600 |
| A | `api` | `34.29.65.82` | 3600 |
| A | `app` | `34.29.65.82` | 3600 |

## ✅ Checklist

- [ ] Criar IP estático no GCloud
- [ ] Atribuir IP estático à VM
- [ ] Configurar registros DNS no registro.br (modo avançado)
- [ ] Aguardar propagação DNS (2-4 horas)
- [ ] Verificar propagação com `dig` ou `nslookup`
- [ ] Testar acesso aos domínios
- [ ] Fazer deploy do Flutter Web (quando estiver pronto)
- [ ] Configurar volume do Flutter Web no docker-compose

## 🚀 Próximos Passos

1. **Aguardar DNS propagar** (você já está fazendo isso ✅)
2. **Fazer deploy do Flutter Web** (vamos fazer depois)
3. **Atualizar docker-compose** para montar arquivos do Flutter Web
4. **Configurar HTTPS** (opcional, mas recomendado)

