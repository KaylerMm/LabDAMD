# LocalStack Setup Options

## Option 1: Docker (Recommended)

Use the pre-configured Docker Compose setup:

```bash
cd Roteiro6
docker-compose up -d
```

**Advantages:**
- Complete isolated environment
- All services in containers
- Easy cleanup with `docker-compose down`
- Consistent across all machines

**Validation:**
```bash
./scripts/validate.sh
```

---

## Option 2: LocalStack CLI

If you've installed LocalStack CLI with `pip install localstack`:

### Start LocalStack + Services

```bash
cd Roteiro6
./scripts/start-all-cli.sh
```

This will:
1. Start LocalStack in daemon mode
2. Initialize AWS services (S3, DynamoDB, SQS, SNS)
3. Start Storage Service (port 50051)
4. Start Task Service (port 50052)
5. Start API Gateway (port 3000)

### Stop All Services

```bash
./scripts/stop-all-cli.sh
```

### Start Only LocalStack

```bash
./scripts/start-localstack-cli.sh
```

Then manually start each service:

```bash
# Terminal 1 - Storage Service
cd services/storage-service
npm install
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
S3_BUCKET=shopping-images \
node index.js

# Terminal 2 - Task Service
cd services/task-service
npm install
AWS_ENDPOINT=http://localhost:4566 \
AWS_REGION=us-east-1 \
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
DYNAMODB_TABLE=tasks \
SQS_QUEUE_URL=http://localhost:4566/000000000000/task-queue \
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:task-notifications \
node index.js

# Terminal 3 - API Gateway
cd api-gateway
npm install
STORAGE_SERVICE_URL=localhost:50051 \
TASK_SERVICE_URL=localhost:50052 \
node index.js
```

---

## Validation Commands

Both options use the same validation:

```bash
# Check LocalStack status
localstack status

# List S3 buckets
awslocal s3 ls

# List images in bucket
awslocal s3 ls s3://shopping-images --recursive

# Scan DynamoDB
awslocal dynamodb scan --table-name tasks

# Check API
curl http://localhost:3000/health
```

---

## Comparison

| Feature | Docker Compose | LocalStack CLI |
|---------|---------------|----------------|
| Setup | `docker-compose up` | Multiple commands |
| Isolation | Full containers | Local processes |
| Cleanup | `docker-compose down` | Kill processes |
| Port conflicts | Isolated | Can conflict |
| Logs | `docker-compose logs` | Terminal output |
| Best for | Demo/Production | Development |

---

## Recommendation

- **For demonstration**: Use Docker Compose
- **For active development**: Use LocalStack CLI
- **For classroom**: Use Docker Compose (easier to show)

---

## Troubleshooting

### LocalStack CLI not found
```bash
pip install localstack
pip install awscli-local
```

### Port already in use
```bash
lsof -ti:4566 | xargs kill -9
lsof -ti:3000 | xargs kill -9
```

### Check LocalStack logs
```bash
localstack logs
```

### Reset LocalStack
```bash
localstack stop
rm -rf ~/.localstack
localstack start -d
```
