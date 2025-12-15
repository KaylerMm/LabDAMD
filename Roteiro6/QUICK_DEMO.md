# 🎬 Guia Rápido de Demonstração - LocalStack

## ⚡ Setup Rápido (5 minutos)

```bash
cd Roteiro6
./setup-demo.sh
```

Isso vai:
- Instalar dependências
- Iniciar containers Docker
- Validar todos os serviços

---

## 🎯 Demonstração ao Vivo

### 1. Mostrar Infraestrutura (2 min)

```bash
# Containers rodando
docker ps

# Bucket S3 existe
awslocal s3 ls

# Bucket está vazio inicialmente
awslocal s3 ls s3://shopping-images --recursive
```

### 2. Executar App Mobile (5 min)

```bash
cd flutter_task_manager
flutter run
```

**No app:**
1. Clique no botão `+`
2. Título: "Produto Demo"
3. Descrição: "Demonstração LocalStack S3"
4. Clique "Adicionar Foto" → Tire uma foto
5. Clique "Salvar Tarefa"

### 3. Validar no LocalStack (3 min)

```bash
# Ver imagem no S3
awslocal s3 ls s3://shopping-images --recursive

# Ver dados no DynamoDB
awslocal dynamodb scan --table-name tasks --output json | jq '.Items[] | {titulo: .title.S, imagem: .imageKey.S}'

# Ver mensagens no SQS
awslocal sqs receive-message --queue-url http://localhost:4566/000000000000/task-queue --output json | jq '.Messages[0].Body | fromjson'
```

### 4. Mostrar Arquitetura (2 min)

**Explique o fluxo:**
```
Flutter App → API Gateway → Storage Service → S3 (LocalStack)
                        → Task Service → DynamoDB (LocalStack)
                                      → SQS (LocalStack)
                                      → SNS (LocalStack)
```

---

## 🧪 Demo Alternativo (Sem Mobile)

Se o Flutter não funcionar, use curl:

```bash
./scripts/test-upload.sh
```

Isso cria uma tarefa com imagem via API e valida tudo automaticamente.

---

## 📊 Comandos Úteis Durante Demo

```bash
# Logs em tempo real
docker-compose logs -f storage-service

# Contar imagens no S3
awslocal s3 ls s3://shopping-images --recursive | wc -l

# Ver detalhes de uma imagem
IMAGE_KEY=$(awslocal s3 ls s3://shopping-images --recursive | head -1 | awk '{print $4}')
awslocal s3api head-object --bucket shopping-images --key $IMAGE_KEY

# Baixar uma imagem
awslocal s3 cp s3://shopping-images/$IMAGE_KEY /tmp/demo-image.jpg
xdg-open /tmp/demo-image.jpg
```

---

## 🎓 Pontos Para Destacar

### LocalStack
- ✅ AWS local sem custos
- ✅ Desenvolvimento offline
- ✅ Testes rápidos
- ✅ CI/CD friendly

### Arquitetura
- ✅ Microserviços (gRPC)
- ✅ API Gateway (REST)
- ✅ Separação de responsabilidades
- ✅ Pronto para produção

### AWS Services
- ✅ **S3**: Armazenamento de objetos
- ✅ **DynamoDB**: NoSQL rápido
- ✅ **SQS**: Fila de mensagens
- ✅ **SNS**: Pub/Sub notifications

---

## 🆘 Troubleshooting Rápido

### Services não iniciam
```bash
docker-compose down -v
docker-compose up -d
sleep 15
```

### LocalStack não responde
```bash
docker-compose restart localstack
sleep 10
```

### App não conecta
```bash
# Descubra seu IP
ip addr show | grep inet

# No Flutter, use: http://SEU_IP:3000
# Para emulador Android: http://10.0.2.2:3000
```

---

## 🧹 Cleanup

```bash
docker-compose down
```

Para limpar volumes também:
```bash
docker-compose down -v
```

---

## ⏱️ Timeline da Demo

- **0-2 min**: Setup e verificação
- **2-4 min**: Mostrar containers e AWS services
- **4-9 min**: Demo mobile com foto
- **9-12 min**: Validação no LocalStack
- **12-15 min**: Q&A

**Total: ~15 minutos**
