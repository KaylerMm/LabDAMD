# Setup Guide

## Quick Start

### 1. Start Everything
```bash
./scripts/start-demo.sh
```

### 2. Validate Installation
```bash
./scripts/validate.sh
```

### 3. Test Upload
```bash
./scripts/test-upload.sh
```

## Detailed Setup

### Backend Services

1. **Install dependencies**:
```bash
cd services/storage-service && npm install
cd ../task-service && npm install
cd ../../api-gateway && npm install
```

2. **Start with Docker**:
```bash
docker-compose up -d
```

3. **Check logs**:
```bash
docker-compose logs -f
```

### Mobile App

1. **Install Flutter dependencies**:
```bash
cd flutter_task_manager
flutter pub get
```

2. **Configure API URL** in `lib/main.dart`:
   - Android Emulator: `http://10.0.2.2:3000`
   - iOS Simulator: `http://localhost:3000`
   - Physical Device: `http://YOUR_IP:3000`

3. **Run the app**:
```bash
flutter run
```

## AWS CLI Configuration

### Install AWS CLI Local
```bash
pip install awscli-local
```

### List S3 Buckets
```bash
awslocal s3 ls
```

### List Bucket Contents
```bash
awslocal s3 ls s3://shopping-images --recursive
```

### Query DynamoDB
```bash
awslocal dynamodb scan --table-name tasks
```

### Check SQS Messages
```bash
awslocal sqs receive-message \
  --queue-url http://localhost:4566/000000000000/task-queue
```

### List SNS Topics
```bash
awslocal sns list-topics
```

## Port Configuration

- LocalStack: 4566
- Storage Service: 50051
- Task Service: 50052
- API Gateway: 3000

## Environment Variables

### Storage Service
```
AWS_ENDPOINT=http://localstack:4566
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
S3_BUCKET=shopping-images
```

### Task Service
```
AWS_ENDPOINT=http://localstack:4566
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
DYNAMODB_TABLE=tasks
SQS_QUEUE_URL=http://localstack:4566/000000000000/task-queue
SNS_TOPIC_ARN=arn:aws:sns:us-east-1:000000000000:task-notifications
```

## Common Issues

### LocalStack not ready
Wait 10-15 seconds after starting:
```bash
sleep 15
./scripts/validate.sh
```

### Port conflicts
Stop other services using ports 3000, 4566, 50051, 50052:
```bash
lsof -ti:3000 | xargs kill -9
lsof -ti:4566 | xargs kill -9
```

### Flutter can't connect
1. Find your IP: `ifconfig` or `ipconfig`
2. Update `lib/main.dart`
3. Restart the app
