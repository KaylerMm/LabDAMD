# 📚 ÍNDICE GERAL - SISTEMA DE UPLOAD AWS LOCALSTACK

## 🎯 Início Rápido

1. **[COMANDOS_RAPIDOS.md](COMANDOS_RAPIDOS.md)** ⚡
   - Comandos essenciais de uma linha
   - Troubleshooting rápido
   - Atalhos para debug

2. **[ROTEIRO_APRESENTACAO.md](ROTEIRO_APRESENTACAO.md)** 🎬
   - Roteiro passo a passo para apresentar ao professor
   - Timing de cada seção
   - Troubleshooting durante apresentação

## 📖 Documentação

3. **[README_UPLOAD.md](README_UPLOAD.md)** 📘
   - Documentação completa do sistema
   - Arquitetura e fluxo de dados
   - Endpoints da API
   - Exemplos de uso

4. **[INTEGRACAO_FLUTTER.md](INTEGRACAO_FLUTTER.md)** 📱
   - Como integrar com o app Flutter
   - Dependências necessárias
   - Permissões Android
   - Código exemplo

## 🚀 Scripts de Automação

5. **[START_UPLOAD.sh](START_UPLOAD.sh)** ▶️
   - Inicia todo o sistema
   - LocalStack + API + ADB

6. **[STOP_UPLOAD.sh](STOP_UPLOAD.sh)** ⏹️
   - Para todos os serviços

7. **[TEST_UPLOAD.sh](TEST_UPLOAD.sh)** 🧪
   - Testa 6 pontos do sistema
   - Validação automatizada

8. **[init-aws.sh](init-aws.sh)** 🔧
   - Inicialização dos recursos AWS
   - Executado automaticamente pelo LocalStack

## 💻 Código Fonte

### Backend
9. **[server_upload.js](server_simples/server_upload.js)** 🖥️
   - API Node.js completa
   - Upload Base64 e Multipart
   - Integração com S3, DynamoDB, SQS, SNS

10. **[package.json](server_simples/package.json)** 📦
    - Dependências do servidor
    - Scripts npm

### Frontend Flutter
11. **[FLUTTER_UPLOAD_SERVICE.dart](FLUTTER_UPLOAD_SERVICE.dart)** 📸
    - Serviço de upload de imagens
    - Captura de câmera e galeria
    - API client

12. **[FLUTTER_CAMERA_SCREEN.dart](FLUTTER_CAMERA_SCREEN.dart)** 🎨
    - Tela de upload de fotos
    - Grid de imagens
    - UI completa

## ⚙️ Configuração

13. **[docker-compose.yml](docker-compose.yml)** 🐳
    - Configuração do LocalStack
    - Portas e volumes
    - Serviços AWS simulados

## 📊 Diagramas e Arquitetura

### Fluxo de Dados
```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │ POST /api/upload/base64
       ↓
┌─────────────┐
│   API REST  │
│  (Node.js)  │
└──────┬──────┘
       │
       ├──→ S3 (Imagem)
       ├──→ DynamoDB (Metadados)
       └──→ SNS (Notificação)
              └──→ SQS (Fila)
```

### Serviços AWS Simulados
- **S3**: Bucket `shopping-images`
- **DynamoDB**: Tabela `TaskImages`
- **SQS**: Fila `image-upload-queue`
- **SNS**: Tópico `image-upload-notifications`

## 🎓 Pontuação (31 pontos)

| Requisito | Pontos | Status |
|-----------|--------|--------|
| Funcionalidade completa | 10 | ✅ |
| AWS S3 | 5 | ✅ |
| DynamoDB | 5 | ✅ |
| SQS/SNS | 5 | ✅ |
| Testes automatizados | 3 | ✅ |
| Documentação | 3 | ✅ |
| **TOTAL** | **31** | **✅** |

## 🔍 Como Navegar

### Para Apresentação
1. Leia **ROTEIRO_APRESENTACAO.md** primeiro
2. Pratique com **COMANDOS_RAPIDOS.md**
3. Execute **./START_UPLOAD.sh**
4. Teste com **./TEST_UPLOAD.sh**

### Para Desenvolvimento
1. Leia **README_UPLOAD.md** para entender arquitetura
2. Veja **INTEGRACAO_FLUTTER.md** para código Flutter
3. Consulte **server_upload.js** para API
4. Use **COMANDOS_RAPIDOS.md** para debug

### Para Troubleshooting
1. **COMANDOS_RAPIDOS.md** → Seção Debug
2. Logs: `tail -f server_simples/upload_server.log`
3. LocalStack: `docker logs localstack-demo`

## 📞 Checklist Pré-Demo

- [ ] Docker rodando
- [ ] LocalStack instalado
- [ ] Node.js instalado
- [ ] Dependências instaladas (`npm install`)
- [ ] Dispositivo Android conectado
- [ ] ADB configurado
- [ ] Scripts executáveis (`chmod +x *.sh`)
- [ ] Praticou o roteiro 2x

## 🆘 Em Caso de Erro

### Sistema não inicia
```bash
./STOP_UPLOAD.sh
docker system prune -f
./START_UPLOAD.sh
```

### API não responde
```bash
pkill -f "node server_upload.js"
cd server_simples && node server_upload.js
```

### App não conecta
```bash
adb reverse tcp:3000 tcp:3000
adb reverse tcp:4566 tcp:4566
```

## 📚 Recursos Externos

- [LocalStack Docs](https://docs.localstack.cloud/)
- [AWS S3 API Reference](https://docs.aws.amazon.com/s3/)
- [Flutter Image Picker](https://pub.dev/packages/image_picker)
- [Express.js Guide](https://expressjs.com/)

## 📝 Ordem de Leitura Recomendada

1. **README_UPLOAD.md** - Entender o sistema
2. **ROTEIRO_APRESENTACAO.md** - Preparar apresentação
3. **COMANDOS_RAPIDOS.md** - Memorizar comandos
4. **INTEGRACAO_FLUTTER.md** - Integrar com app
5. Executar scripts de teste
6. Praticar apresentação

---

## 🎯 Meta

**Garantir 31 pontos no trabalho!** 🏆

---

**Criado para Lab de Aplicações Móveis - PUC** 🎓
**Professor: [Nome do Professor]**
**Aluno: Kayler Moura**
**Data: [Data da Apresentação]**
