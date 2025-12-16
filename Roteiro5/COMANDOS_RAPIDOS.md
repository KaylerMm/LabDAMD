# ⚡ COMANDOS RÁPIDOS - UPLOAD SYSTEM

## 🚀 Inicialização

```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5"
./START_UPLOAD.sh
```

## 🧪 Testar Sistema

```bash
./TEST_UPLOAD.sh
```

## 🛑 Parar Sistema

```bash
./STOP_UPLOAD.sh
```

## 📊 Verificações Rápidas

### Status do LocalStack
```bash
docker ps | grep localstack
curl http://localhost:4566/_localstack/health
```

### Status da API
```bash
curl http://localhost:3000/api/health
```

### Listar imagens no S3
```bash
docker exec localstack-demo awslocal s3 ls s3://shopping-images/
```

### Ver dados no DynamoDB
```bash
docker exec localstack-demo awslocal dynamodb scan --table-name TaskImages
```

### Ver fila SQS
```bash
docker exec localstack-demo awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/image-upload-queue
```

## 📱 Configuração Android

```bash
# Ver dispositivos
adb devices

# Port forwarding
adb reverse tcp:3000 tcp:3000
adb reverse tcp:4566 tcp:4566
```

## 📝 Logs

```bash
# Logs do servidor
tail -f /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/server_simples/upload_server.log

# Logs do LocalStack
docker logs -f localstack-demo
```

## 🧹 Limpeza

```bash
# Parar tudo
docker-compose down

# Limpar dados do LocalStack
rm -rf localstack-data/

# Matar processos Node.js
pkill -f "node server_upload.js"
```

## 🔥 Reset Completo

```bash
./STOP_UPLOAD.sh
docker system prune -f
rm -rf localstack-data/
./START_UPLOAD.sh
```

## 📸 Teste de Upload Manual

```bash
# Criar imagem de teste
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" > test.b64

# Upload via curl
curl -X POST http://localhost:3000/api/upload/base64 \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==",
    "taskId": "test-123",
    "description": "Teste manual"
  }'
```

## 🔍 Debug

```bash
# Verificar porta 3000 em uso
lsof -i :3000

# Verificar porta 4566 em uso  
lsof -i :4566

# Ver processos Node.js
ps aux | grep node

# Ver containers Docker
docker ps -a
```

## 📦 Reinstalar Dependências

```bash
cd /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/server_simples
rm -rf node_modules package-lock.json
npm install
```

## 🎯 One-Liner para Demo

```bash
cd "/home/kayler/Puc/Lab App Mov/Roteiro5" && ./START_UPLOAD.sh && sleep 20 && ./TEST_UPLOAD.sh
```

---

**Salvou este arquivo? Adicione aos favoritos do terminal! 📌**
