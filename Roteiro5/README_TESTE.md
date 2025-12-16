# 🎯 Roteiro de Teste - Sistema de Mensageria RabbitMQ

Este diretório contém um sistema completo de mensageria com RabbitMQ para demonstrar comunicação assíncrona entre microsserviços.

## 📋 Arquivos de Teste

| Arquivo | Descrição |
|---------|-----------|
| `ROTEIRO_GUIADO.md` | 📚 **Roteiro completo** passo-a-passo com explicações detalhadas |
| `COMANDOS_TESTE.md` | ⚡ **Referência rápida** de comandos para quem já conhece o sistema |
| `setup-demo.sh` | 🚀 **Script de setup** automático da infraestrutura |
| `validacao-rapida.sh` | ✅ **Validação express** para verificar se tudo está funcionando |
| `test-checkout.js` | 🧪 **Teste automatizado** completo do fluxo de checkout |

## 🎬 Como Começar

### Opção 1: Roteiro Completo (Recomendado para primeira vez)
```bash
# Leia o roteiro completo
cat ROTEIRO_GUIADO.md

# Execute setup automático
./setup-demo.sh

# Siga as instruções do roteiro
```

### Opção 2: Teste Rápido (Para quem já conhece)
```bash
# Setup rápido
./setup-demo.sh

# Iniciar serviços (6 terminais conforme COMANDOS_TESTE.md)
# ...

# Validação automática
./validacao-rapida.sh
```

### Opção 3: Apenas Teste Automatizado
```bash
# Assumindo que tudo já está rodando
node test-checkout.js
```

## 🏗️ Arquitetura do Sistema

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   API Gateway   │───▶│   List Service   │───▶│   RabbitMQ      │
│   (Port 3000)   │    │   (Port 3002)    │    │ shopping_events │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                         ┌───────────────────────────────┴─────────────┐
                         │                                             │
                         ▼                                             ▼
               ┌─────────────────┐                           ┌─────────────────┐
               │ Notification    │                           │ Analytics       │
               │ Consumer        │                           │ Consumer        │
               │ (Email Sim.)    │                           │ (Dashboard)     │
               └─────────────────┘                           └─────────────────┘
```

## ⚡ Fluxo de Teste Principal

1. **Setup** → `./setup-demo.sh`
2. **Iniciar Serviços** → 6 terminais conforme roteiro
3. **Checkout** → API retorna 202, mensagem vai para RabbitMQ
4. **Consumers** → Processam mensagem (email + analytics)
5. **Validação** → `./validacao-rapida.sh`

## 🎯 Pontos de Validação

- ✅ **Resposta 202** no checkout (não 200!)
- ✅ **Consumers processando** instantaneamente
- ✅ **RabbitMQ Management** mostrando estatísticas
- ✅ **Performance** < 50ms no checkout

## 📞 Suporte

Se algo não funcionar:
1. Verifique o **Troubleshooting** no `ROTEIRO_GUIADO.md`
2. Execute `./validacao-rapida.sh` para diagnóstico
3. Consulte logs dos containers: `docker compose logs`

---

**🎉 Boa demonstração!** Este sistema está pronto para apresentação em aula.