# 🎯 ROTEIRO PARA APRESENTAÇÃO - 31 PONTOS

## 📋 Checklist Pré-Apresentação

### Infraestrutura
- [ ] Docker instalado e rodando
- [ ] LocalStack instalado
- [ ] Node.js instalado
- [ ] Dispositivo Android conectado via USB
- [ ] ADB configurado

### Arquivos Verificados
- [ ] `docker-compose.yml` com LocalStack
- [ ] `init-aws.sh` (script de inicialização)
- [ ] `server_upload.js` (API de upload)
- [ ] Scripts de automação (START_UPLOAD.sh, STOP_UPLOAD.sh, TEST_UPLOAD.sh)

---

## 🎬 ROTEIRO DA APRESENTAÇÃO

### 1️⃣ INTRODUÇÃO (2 min)

**O que vai dizer:**
> "Professor, desenvolvi um sistema completo de upload de fotos que simula a AWS usando LocalStack. O sistema permite tirar fotos do celular e salvá-las em um bucket S3 simulado, com metadados no DynamoDB, fila SQS para processamento e notificações SNS. Tudo gratuito e local."

**Mostrar slide/diagrama:**
```
📱 App Flutter → 🔌 API REST → ☁️ LocalStack
                                  ├─ S3 (Imagens)
                                  ├─ DynamoDB (Metadados)
                                  ├─ SQS (Fila)
                                  └─ SNS (Notificações)
```

---

### 2️⃣ INICIAR SISTEMA (3 min)

**Terminal 1 - Iniciar infraestrutura:**
```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
./START_UPLOAD.sh
```

**Explicar enquanto inicia:**
> "Este script automatiza toda a inicialização:
> 1. Sobe o LocalStack no Docker
> 2. Cria bucket S3 'shopping-images'
> 3. Cria tabela DynamoDB 'TaskImages'
> 4. Configura fila SQS e tópico SNS
> 5. Inicia API Node.js na porta 3000
> 6. Configura port forwarding do ADB"

**Aguardar mensagem:**
```
✅ SISTEMA PRONTO PARA USO!
```

---

### 3️⃣ VALIDAR INFRAESTRUTURA (2 min)

**Terminal 2 - Executar testes:**
```bash
./TEST_UPLOAD.sh
```

**Explicar os testes:**
> "Aqui estou validando 6 pontos:
> 1. Health check da API ✅
> 2. Upload de imagem Base64 ✅
> 3. Verificação no S3 ✅
> 4. Verificação no DynamoDB ✅
> 5. API de listagem ✅
> 6. Busca por taskId ✅"

---

### 4️⃣ DEMONSTRAÇÃO AWS CLI (3 min)

**Mostrar recursos criados:**

```bash
# Listar bucket S3
docker exec localstack-demo awslocal s3 ls s3://shopping-images/
```

```bash
# Ver tabela DynamoDB
docker exec localstack-demo awslocal dynamodb scan --table-name TaskImages
```

```bash
# Ver fila SQS
docker exec localstack-demo awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/image-upload-queue
```

```bash
# Ver tópico SNS
docker exec localstack-demo awslocal sns list-topics
```

**Explicar:**
> "Todos os serviços AWS estão rodando localmente. O LocalStack simula perfeitamente o comportamento da AWS real, mas de graça."

---

### 5️⃣ DEMONSTRAÇÃO NO APP FLUTTER (5 min)

**No dispositivo Android:**

1. **Abrir o app**
2. **Navegar para tela de câmera** (mostrar código se tiver)
3. **Tirar foto**
4. **Mostrar upload acontecendo**
5. **Confirmar sucesso**

**Enquanto faz upload, explicar:**
> "A foto é capturada, convertida para Base64 e enviada para a API. A API então:
> 1. Salva no S3 (armazenamento)
> 2. Registra metadados no DynamoDB
> 3. Publica notificação no SNS
> 4. SNS envia para fila SQS"

---

### 6️⃣ VALIDAR UPLOAD NO TERMINAL (2 min)

**Após upload no app:**

```bash
# Ver nova imagem no S3
docker exec localstack-demo awslocal s3 ls s3://shopping-images/
```

```bash
# Ver metadados no DynamoDB
docker exec localstack-demo awslocal dynamodb scan \
  --table-name TaskImages \
  | grep -A 5 "imageId"
```

```bash
# Ver mensagem na fila SQS
docker exec localstack-demo awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/image-upload-queue
```

**Explicar:**
> "Veja que a imagem está no S3, os metadados no DynamoDB e a mensagem foi processada pela fila SQS."

---

### 7️⃣ MOSTRAR CÓDIGO (3 min)

**API Backend - server_upload.js:**

```javascript
// Mostrar função de upload (linhas 30-80)
// Destacar:
// 1. Conversão Base64 → Buffer
// 2. Upload para S3
// 3. Salvamento no DynamoDB
// 4. Publicação no SNS
```

**Flutter Service:**

```dart
// Mostrar ImageUploadService
// Destacar:
// 1. Captura de imagem
// 2. Conversão para Base64
// 3. POST para API
```

---

### 8️⃣ DEMONSTRAÇÃO ADICIONAL (2 min)

**Listar imagens via API:**

```bash
curl http://localhost:3000/api/images | jq
```

**Buscar imagens de uma task específica:**

```bash
curl http://localhost:3000/api/images/task-123 | jq
```

**Acessar imagem direto pelo browser:**
```
http://localhost:4566/shopping-images/[IMAGE_ID].jpg
```

---

### 9️⃣ ARQUITETURA E BENEFÍCIOS (2 min)

**Explicar vantagens:**

> "Este sistema demonstra:
> 
> ✅ **Escalabilidade**: S3 para armazenamento ilimitado
> ✅ **Performance**: DynamoDB NoSQL de alta velocidade
> ✅ **Desacoplamento**: SQS para processamento assíncrono
> ✅ **Notificações**: SNS para eventos em tempo real
> ✅ **Custo Zero**: LocalStack para desenvolvimento
> ✅ **Cloud-Ready**: Código pronto para produção na AWS real"

---

### 🔟 CONCLUSÃO (1 min)

**Resumo:**

> "Implementei um sistema completo que:
> - Captura fotos do celular ✅
> - Faz upload para AWS S3 (simulado) ✅
> - Armazena metadados no DynamoDB ✅
> - Processa via fila SQS ✅
> - Notifica via SNS ✅
> - Tudo automatizado e testado ✅
> - 100% gratuito com LocalStack ✅"

**Perguntar:**
> "Professor, alguma dúvida ou gostaria de ver alguma parte específica?"

---

## 🚨 TROUBLESHOOTING DURANTE APRESENTAÇÃO

### Se LocalStack não iniciar:
```bash
docker-compose down
docker system prune -f
docker-compose up -d localstack
```

### Se API não responder:
```bash
pkill -f "node server_upload.js"
cd server_simples
node server_upload.js
```

### Se app não conectar:
```bash
adb devices
adb reverse tcp:3000 tcp:3000
adb reverse tcp:4566 tcp:4566
```

### Se teste falhar:
```bash
# Ver logs do servidor
tail -f server_simples/upload_server.log

# Ver logs do LocalStack
docker logs localstack-demo
```

---

## 📊 MÉTRICAS PARA MENCIONAR

- **Tempo de resposta**: < 500ms para upload
- **Tamanho máximo**: 10MB por imagem
- **Compressão**: JPEG com quality=85
- **Resolução máxima**: 1920x1080
- **Serviços AWS**: 4 (S3, DynamoDB, SQS, SNS)
- **Endpoints**: 5 (upload, list, get, delete, health)
- **Testes**: 6 validações automatizadas

---

## 🎯 PONTOS QUE GARANTEM A NOTA

1. ✅ **Funcionalidade** (10 pts): Upload funcionando perfeitamente
2. ✅ **AWS S3** (5 pts): Imagens no bucket LocalStack
3. ✅ **DynamoDB** (5 pts): Metadados persistidos
4. ✅ **SQS/SNS** (5 pts): Mensageria implementada
5. ✅ **Testes** (3 pts): Suite de testes automatizada
6. ✅ **Documentação** (3 pts): README completo

**TOTAL: 31 pontos** 🎉

---

## 📝 NOTAS IMPORTANTES

- Chegar 10 min antes para testar tudo
- Ter o celular carregado
- Ter imagens de backup caso a câmera falhe
- Praticar o roteiro pelo menos 2x
- Ter o README_UPLOAD.md aberto para consulta
- Preparar para perguntas sobre escalabilidade

---

**BOA SORTE! 🍀**
