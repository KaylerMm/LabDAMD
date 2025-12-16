# 📸 GUIA DE TESTE - UPLOAD DE FOTO

## ✅ Pré-requisitos Verificados
- [x] LocalStack rodando na porta 4566
- [x] Servidor de upload rodando na porta 3000
- [x] Bucket S3 `shopping-images` criado
- [x] Tabela DynamoDB `TaskImages` criada
- [x] Fila SQS criada
- [x] Tópico SNS criado
- [x] App Flutter compilando
- [x] Dispositivo Android conectado (fcdb13cf)

## 📱 PASSO A PASSO NO CELULAR

### 1. Abrir o App
- O app será instalado automaticamente após o build
- Nome: **Task Manager Offline**

### 2. Criar uma Task (se não tiver)
- Clique no botão **+** (canto inferior direito)
- Digite um título: "Teste de Upload"
- Clique em **Salvar**

### 3. Adicionar Foto
- Na lista de tasks, você verá um ícone de **câmera 📷** ao lado de cada task
- Clique no ícone da câmera
- Você será levado para a tela de fotos

### 4. Tirar Foto
Você tem 2 opções:

**Opção A - Câmera:**
- Clique no botão **"CÂMERA"**
- Tire uma foto
- Confirme a foto
- Aguarde o upload (aparecerá um indicador de progresso)
- Mensagem verde: "✅ Foto enviada com sucesso!"

**Opção B - Galeria:**
- Clique no botão **"GALERIA"**
- Selecione uma foto existente
- Aguarde o upload
- Mensagem verde: "✅ Foto enviada com sucesso!"

### 5. Ver Fotos Enviadas
- As fotos aparecerão em um grid 2x2 na tela
- Você pode ver:
  - A imagem (carregada do S3)
  - Data/hora do upload
  - Botão de deletar (X vermelho)

## 🖥️ VALIDAÇÃO NO TERMINAL

Assim que você enviar uma foto, execute estes comandos no terminal:

### Verificar no S3
```bash
docker exec localstack awslocal s3 ls s3://shopping-images/
```

**Resultado esperado:**
```
2025-12-16 00:XX:XX    XXXXX abc-123-def.jpg
```

### Verificar no DynamoDB
```bash
docker exec localstack awslocal dynamodb scan --table-name TaskImages | jq '.Items[] | {imageId: .imageId.S, taskId: .taskId.S, uploadedAt: .uploadedAt.S}'
```

**Resultado esperado:**
```json
{
  "imageId": "abc-123-def",
  "taskId": "task-123",
  "uploadedAt": "2025-12-16T00:XX:XX.XXXZ"
}
```

### Verificar na Fila SQS
```bash
docker exec localstack awslocal sqs receive-message --queue-url http://localhost:4566/000000000000/image-upload-queue
```

**Resultado esperado:**
Mensagem com os dados do upload

### Baixar Imagem do S3
```bash
docker exec localstack awslocal s3 cp s3://shopping-images/[IMAGE_ID].jpg /tmp/downloaded.jpg
```

### Ver a Imagem no Browser
```
http://localhost:4566/shopping-images/[IMAGE_ID].jpg
```

## 🐛 TROUBLESHOOTING

### Foto não sobe
1. Verificar se servidor está rodando:
   ```bash
   curl http://localhost:3000/api/health
   ```

2. Verificar logs do servidor:
   ```bash
   tail -f /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/server_simples/upload_server.log
   ```

3. Verificar port forwarding:
   ```bash
   adb reverse tcp:3000 tcp:3000
   adb reverse tcp:4566 tcp:4566
   ```

### Erro de permissão câmera
1. Nas configurações do Android:
   - Configurações → Apps → Task Manager
   - Permissões → Câmera → Permitir

2. Ou desinstale e reinstale o app

### Imagem não aparece
1. Verificar conectividade:
   ```bash
   adb shell ping -c 1 localhost
   ```

2. Testar URL manualmente no navegador do celular:
   ```
   http://localhost:4566/shopping-images/[IMAGE_ID].jpg
   ```

## 📊 DEMONSTRAÇÃO PARA O PROFESSOR

### Roteiro Curto (5 min):

1. **Mostrar sistema rodando:**
   ```bash
   docker ps | grep localstack
   curl http://localhost:3000/api/health
   ```

2. **No celular:**
   - Abrir app
   - Selecionar uma task
   - Clicar no ícone de câmera
   - Tirar foto
   - Mostrar mensagem de sucesso
   - Mostrar foto na galeria

3. **No terminal:**
   ```bash
   # Ver imagem no S3
   docker exec localstack awslocal s3 ls s3://shopping-images/ | tail -1
   
   # Ver metadados no DynamoDB
   docker exec localstack awslocal dynamodb scan --table-name TaskImages | jq '.Count'
   
   # Ver mensagem na fila
   docker exec localstack awslocal sqs receive-message \
     --queue-url http://localhost:4566/000000000000/image-upload-queue
   ```

4. **Abrir imagem no browser:**
   ```bash
   # Pegar URL da última imagem
   IMAGE_ID=$(docker exec localstack awslocal s3 ls s3://shopping-images/ | tail -1 | awk '{print $4}')
   echo "http://localhost:4566/shopping-images/$IMAGE_ID"
   ```

5. **Conclusão:**
   - Sistema completo funcionando ✅
   - Upload do celular ✅
   - S3 LocalStack ✅
   - DynamoDB ✅
   - SQS/SNS ✅
   - Tudo gratuito ✅

## 🎯 PONTOS-CHAVE PARA MENCIONAR

- ✅ Captura de foto via câmera nativa
- ✅ Upload assíncrono com feedback visual
- ✅ Armazenamento em S3 (LocalStack)
- ✅ Metadados em DynamoDB NoSQL
- ✅ Mensageria com SQS e SNS
- ✅ Arquitetura cloud-ready
- ✅ 100% gratuito para desenvolvimento
- ✅ Pode migrar para AWS real mudando apenas endpoint

---

**BOA SORTE NO TESTE! 🍀**
