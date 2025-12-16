# 📸 Sistema de Upload de Imagens com AWS LocalStack

Sistema completo de upload de imagens simulando AWS S3, DynamoDB, SQS e SNS usando LocalStack.

## 🎯 Arquitetura

```
Flutter App → REST API → LocalStack AWS Services
                ↓
              ├─ S3 (Armazenamento de imagens)
              ├─ DynamoDB (Metadados)
              ├─ SQS (Fila de processamento)
              └─ SNS (Notificações)
```

## 🚀 Início Rápido

### 1. Iniciar o Sistema

```bash
./START_UPLOAD.sh
```

Isso irá:
- ✅ Iniciar LocalStack no Docker
- ✅ Criar bucket S3 `shopping-images`
- ✅ Criar tabela DynamoDB `TaskImages`
- ✅ Criar fila SQS `image-upload-queue`
- ✅ Criar tópico SNS `image-upload-notifications`
- ✅ Iniciar servidor Node.js na porta 3000
- ✅ Configurar ADB port forwarding

### 2. Testar o Sistema

```bash
./TEST_UPLOAD.sh
```

### 3. Parar o Sistema

```bash
./STOP_UPLOAD.sh
```

## 📡 Endpoints da API

### Health Check
```bash
GET http://localhost:3000/api/health
```

### Upload Base64 (Recomendado para Flutter)
```bash
POST http://localhost:3000/api/upload/base64
Content-Type: application/json

{
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  "taskId": "task-123",
  "description": "Foto da tarefa"
}
```

**Resposta:**
```json
{
  "success": true,
  "imageId": "abc-123-def",
  "url": "http://localhost:4566/shopping-images/abc-123-def.jpg",
  "message": "Imagem enviada com sucesso!"
}
```

### Upload Multipart
```bash
POST http://localhost:3000/api/upload/multipart
Content-Type: multipart/form-data

Form fields:
- image: [arquivo]
- taskId: task-123
- description: Foto da tarefa
```

### Listar Todas as Imagens
```bash
GET http://localhost:3000/api/images
```

### Listar Imagens de uma Task
```bash
GET http://localhost:3000/api/images/:taskId
```

### Deletar Imagem
```bash
DELETE http://localhost:3000/api/images/:imageId
```

## 🔧 Comandos Úteis AWS CLI

### Listar objetos no S3
```bash
docker exec localstack-demo awslocal s3 ls s3://shopping-images/
```

### Download de imagem do S3
```bash
docker exec localstack-demo awslocal s3 cp s3://shopping-images/IMAGE_ID.jpg /tmp/
```

### Consultar DynamoDB
```bash
docker exec localstack-demo awslocal dynamodb scan --table-name TaskImages
```

### Ver mensagens na fila SQS
```bash
docker exec localstack-demo awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/image-upload-queue
```

### Ver notificações SNS (subscriptions)
```bash
docker exec localstack-demo awslocal sns list-subscriptions
```

## 📱 Integração com Flutter

### 1. Adicionar Dependências

```yaml
dependencies:
  image_picker: ^1.0.7
  http: ^1.2.0
  path_provider: ^2.1.2
```

### 2. Código de Upload

```dart
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

Future<void> uploadImage(String taskId) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  
  if (image == null) return;
  
  // Ler arquivo como bytes
  final bytes = await File(image.path).readAsBytes();
  
  // Converter para base64
  final base64Image = base64Encode(bytes);
  
  // Enviar para API
  final response = await http.post(
    Uri.parse('http://localhost:3000/api/upload/base64'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': 'data:image/jpeg;base64,$base64Image',
      'taskId': taskId,
      'description': 'Foto da tarefa',
    }),
  );
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Upload sucesso! URL: ${data['url']}');
  }
}
```

### 3. Permissões Android

`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

## 🐳 Docker Compose

O LocalStack está configurado com:
- **Porta 4566**: Gateway para todos os serviços
- **Serviços**: S3, DynamoDB, SQS, SNS
- **Região**: us-east-1
- **Credenciais**: test/test (para desenvolvimento)

## 📊 Fluxo de Dados

1. **Upload**: Cliente → API → S3 (imagem) + DynamoDB (metadados)
2. **Notificação**: API → SNS → SQS (fila para processamento)
3. **Consulta**: Cliente → API → DynamoDB (metadados) + S3 (imagem)

## 🔍 Monitoramento

### Ver logs do servidor
```bash
tail -f /home/kayler/Puc/Lab\ App\ Mov/Roteiro5/server_simples/upload_server.log
```

### Ver logs do LocalStack
```bash
docker logs -f localstack-demo
```

### Verificar health do LocalStack
```bash
curl http://localhost:4566/_localstack/health | jq
```

## 🎓 Pontos para o Professor

### ✅ Requisitos Atendidos
- [x] Upload de fotos do celular
- [x] Armazenamento no S3 (LocalStack)
- [x] Metadados no DynamoDB
- [x] Fila SQS para processamento
- [x] Notificações via SNS
- [x] API REST completa
- [x] Tudo gratuito (LocalStack)
- [x] Docker Compose para infraestrutura
- [x] Testes automatizados

### 📈 Demonstração

1. Mostrar LocalStack rodando: `docker ps`
2. Executar teste automatizado: `./TEST_UPLOAD.sh`
3. Consultar S3: `awslocal s3 ls s3://shopping-images/`
4. Consultar DynamoDB: `awslocal dynamodb scan --table-name TaskImages`
5. Ver mensagens SQS
6. Demo no app Flutter

## 🔧 Troubleshooting

### LocalStack não inicia
```bash
docker-compose down
docker-compose up -d localstack
docker logs localstack-demo
```

### Servidor não conecta
```bash
pkill -f "node server_upload.js"
cd server_simples && node server_upload.js
```

### ADB não funciona
```bash
adb devices
adb reverse tcp:3000 tcp:3000
adb reverse tcp:4566 tcp:4566
```

## 📚 Recursos

- [LocalStack Docs](https://docs.localstack.cloud/)
- [AWS S3 API](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB](https://docs.aws.amazon.com/dynamodb/)
- [Image Picker Flutter](https://pub.dev/packages/image_picker)

---

**Desenvolvido para Lab de Aplicações Móveis - 31 pontos** 🎯
