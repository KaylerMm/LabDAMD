# Demonstration Guide - Roteiro 6

## Pre-Demonstration Setup

### 1. Prepare Environment (5 minutes before)
```bash
cd Roteiro6
docker-compose up -d
sleep 15
./scripts/validate.sh
```

### 2. Open Terminals
- Terminal 1: For AWS CLI commands
- Terminal 2: For Docker logs
- Terminal 3: For Flutter app

### 3. Test Connection
```bash
curl http://localhost:3000/health
```

## Demonstration Flow (10-15 minutes)

### Part 1: Infrastructure (3 minutes)

**Show running containers:**
```bash
docker ps
```

**Explain architecture:**
- LocalStack simulates AWS services
- Storage service handles S3 operations
- Task service manages DynamoDB, SQS, SNS
- API Gateway exposes REST endpoints

**List AWS resources:**
```bash
awslocal s3 ls
```

**Show bucket exists:**
```bash
awslocal s3 ls s3://shopping-images
```

### Part 2: Configuration Verification (2 minutes)

**Check DynamoDB table:**
```bash
awslocal dynamodb describe-table --table-name tasks --output json | jq '.Table.TableName'
```

**List SQS queues:**
```bash
awslocal sqs list-queues
```

**List SNS topics:**
```bash
awslocal sns list-topics
```

### Part 3: Mobile App Demo (5 minutes)

**Start Flutter app:**
```bash
cd flutter_task_manager
flutter run
```

**Demonstrate workflow:**
1. Click "+" button to create new task
2. Enter title: "Produto de Teste"
3. Enter description: "Demonstração LocalStack"
4. Click "Adicionar Foto"
5. Select "Câmera" or "Galeria"
6. Take/select a photo
7. Click "Salvar Tarefa"
8. Show success message
9. Show task in list with image

### Part 4: Validation (3-5 minutes)

**Verify image in S3:**
```bash
awslocal s3 ls s3://shopping-images --recursive
```

**Show bucket contents with details:**
```bash
awslocal s3api list-objects-v2 --bucket shopping-images --output json | jq '.Contents[] | {Key: .Key, Size: .Size}'
```

**Check task in DynamoDB:**
```bash
awslocal dynamodb scan --table-name tasks --output json | jq '.Items[] | {id: .id.S, title: .title.S, imageKey: .imageKey.S}'
```

**Verify SQS message:**
```bash
awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/task-queue \
  --output json | jq '.Messages[0].Body | fromjson'
```

**Optional - Download image:**
```bash
IMAGE_KEY=$(awslocal s3 ls s3://shopping-images --recursive | head -1 | awk '{print $4}')
awslocal s3 cp s3://shopping-images/$IMAGE_KEY /tmp/downloaded_image.jpg
open /tmp/downloaded_image.jpg
```

## Key Points to Highlight

### 1. LocalStack Benefits
- Local AWS development
- No cloud costs
- Fast iteration
- Offline development

### 2. Architecture Benefits
- Microservices with gRPC
- Clean separation of concerns
- Scalable design
- Cloud-ready

### 3. AWS Services Used
- **S3**: Persistent image storage
- **DynamoDB**: Fast NoSQL database
- **SQS**: Reliable message queue
- **SNS**: Pub/sub notifications

### 4. Mobile Integration
- Native camera access
- Image upload from device
- Real-time updates
- Offline-first capable

## Questions to Address

**Q: Why LocalStack?**
A: Simulate AWS locally without costs, perfect for development and testing.

**Q: How does image upload work?**
A: Flutter captures image → Base64 encoding → API Gateway → Storage Service → S3.

**Q: What happens to task data?**
A: Stored in DynamoDB, events sent to SQS queue, notifications via SNS.

**Q: Can this run in real AWS?**
A: Yes! Just change endpoint URLs to real AWS services.

**Q: How to debug issues?**
A: Check Docker logs, verify AWS CLI commands, validate API responses.

## Troubleshooting During Demo

### App won't connect
```bash
ifconfig | grep "inet "
# Update Flutter app with correct IP
```

### LocalStack not responding
```bash
docker-compose restart localstack
sleep 10
```

### Services not starting
```bash
docker-compose logs -f
```

### Clear everything and restart
```bash
docker-compose down -v
docker-compose up -d
sleep 15
```

## Cleanup After Demo
```bash
docker-compose down
```

## Alternative Demo (Without Mobile)

If mobile demo fails, use curl:

```bash
./scripts/test-upload.sh
```

This demonstrates the same flow via command line.

## Time Allocation

- Infrastructure setup: 3 min
- Configuration demo: 2 min
- Mobile app demo: 5 min
- Validation: 3 min
- Q&A: 2 min

**Total: ~15 minutes**
