# Roteiro 6 - Cloud Simulation with LocalStack

## Overview

This project implements a complete cloud infrastructure simulation using LocalStack, featuring AWS services (S3, DynamoDB, SQS, SNS) integrated with a microservices architecture and Flutter mobile app.

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Mobile)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  API Gateway    │
│  (REST API)     │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌─────────┐
│Storage  │ │  Task   │
│Service  │ │ Service │
│(gRPC)   │ │ (gRPC)  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────────┐
│    LocalStack       │
│  • S3               │
│  • DynamoDB         │
│  • SQS              │
│  • SNS              │
└─────────────────────┘
```

## Services

### LocalStack
AWS cloud services simulation running locally:
- **S3**: Object storage for images
- **DynamoDB**: NoSQL database for tasks
- **SQS**: Message queue for task events
- **SNS**: Notification service

### Storage Service (gRPC)
Manages image uploads to S3:
- Upload images in Base64 format
- Generate image URLs
- Delete images
- List images by prefix

### Task Service (gRPC)
Manages task CRUD operations:
- Create tasks with metadata
- Store tasks in DynamoDB
- Publish events to SQS/SNS
- Query tasks by user

### API Gateway (REST)
HTTP REST API that orchestrates gRPC services:
- Image upload endpoint
- Task management endpoints
- Combined task + image creation

### Flutter Mobile App
User interface for task management:
- Take photos with camera
- Select images from gallery
- Create tasks with images
- View task list
- Task details view

## Prerequisites

- Docker and Docker Compose
- Node.js 18+
- Flutter SDK 3.0+
- AWS CLI with LocalStack wrapper
- Android Studio (for mobile development)

## Installation

### 1. Install LocalStack AWS CLI

```bash
pip install awscli-local
```

### 2. Install Dependencies

```bash
cd services/storage-service && npm install
cd ../task-service && npm install
cd ../../api-gateway && npm install
cd ../flutter_task_manager && flutter pub get
```

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

## Usage

### Start Infrastructure

```bash
docker-compose up -d
```

Wait 10-15 seconds for LocalStack to initialize all services.

### Verify Installation

```bash
./scripts/validate.sh
```

Expected output:
```
✓ LocalStack is running
✓ Bucket 'shopping-images' exists
✓ DynamoDB table 'tasks' exists
✓ SQS queue 'task-queue' exists
✓ SNS topic 'task-notifications' exists
✓ API Gateway is healthy
```

### List S3 Buckets

```bash
awslocal s3 ls
```

### List Objects in Bucket

```bash
awslocal s3 ls s3://shopping-images --recursive
```

### Test Upload

```bash
./scripts/test-upload.sh
```

### View DynamoDB Items

```bash
awslocal dynamodb scan --table-name tasks
```

### Run Flutter App

```bash
cd flutter_task_manager
flutter run
```

## API Endpoints

### Upload Image
```
POST /api/upload
Content-Type: application/json

{
  "userId": "user123",
  "taskId": "task456",
  "imageData": "base64_encoded_image",
  "contentType": "image/jpeg"
}
```

### Create Task with Image
```
POST /api/tasks-with-image
Content-Type: application/json

{
  "userId": "user123",
  "title": "Product Name",
  "description": "Product description",
  "imageData": "base64_encoded_image",
  "contentType": "image/jpeg"
}
```

### List Tasks
```
GET /api/tasks?userId=user123
```

### Get Task
```
GET /api/tasks/{taskId}
```

### Update Task
```
PUT /api/tasks/{taskId}
Content-Type: application/json

{
  "title": "Updated title",
  "completed": true
}
```

### Delete Task
```
DELETE /api/tasks/{taskId}
```

## Demonstration Steps (Classroom)

### 1. Infrastructure Setup
```bash
docker-compose up -d
docker ps
```

### 2. Verify LocalStack
```bash
awslocal s3 ls
awslocal s3 ls s3://shopping-images
```

### 3. Run Mobile App
```bash
cd flutter_task_manager
flutter run
```

### 4. Create Task with Photo
- Open the app
- Click "+" button
- Add title and description
- Click "Adicionar Foto"
- Take a photo or select from gallery
- Click "Salvar Tarefa"

### 5. Verify in LocalStack
```bash
awslocal s3 ls s3://shopping-images --recursive

awslocal dynamodb scan --table-name tasks --output json | jq '.Items'
```

### 6. Check SQS Messages
```bash
awslocal sqs receive-message --queue-url http://localhost:4566/000000000000/task-queue
```

## Configuration

### API Gateway URL (Flutter App)

For Android Emulator:
```dart
final apiService = ApiService(baseUrl: 'http://10.0.2.2:3000');
```

For iOS Simulator:
```dart
final apiService = ApiService(baseUrl: 'http://localhost:3000');
```

For Physical Device:
```dart
final apiService = ApiService(baseUrl: 'http://YOUR_MACHINE_IP:3000');
```

## Docker Commands

### View Logs
```bash
docker-compose logs -f
docker-compose logs -f storage-service
docker-compose logs -f task-service
docker-compose logs -f api-gateway
docker-compose logs -f localstack
```

### Restart Services
```bash
docker-compose restart
```

### Stop Services
```bash
docker-compose down
```

### Clean Everything
```bash
docker-compose down -v
```

## Troubleshooting

### LocalStack not initializing
```bash
docker-compose down -v
docker-compose up -d
sleep 15
./scripts/validate.sh
```

### Cannot connect from mobile
1. Check your machine's IP address
2. Update Flutter app configuration
3. Ensure firewall allows port 3000

### Images not appearing
1. Check S3 bucket: `awslocal s3 ls s3://shopping-images --recursive`
2. Verify image URL in API response
3. Check network connectivity

## Project Structure

```
Roteiro6/
├── docker-compose.yml
├── package.json
├── scripts/
│   ├── init-aws.sh
│   ├── validate.sh
│   ├── test-upload.sh
│   └── start-demo.sh
├── services/
│   ├── storage-service/
│   │   ├── index.js
│   │   ├── storage.proto
│   │   ├── package.json
│   │   └── Dockerfile
│   └── task-service/
│       ├── index.js
│       ├── task.proto
│       ├── package.json
│       └── Dockerfile
├── api-gateway/
│   ├── index.js
│   ├── package.json
│   └── Dockerfile
└── flutter_task_manager/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── models/
        ├── services/
        ├── providers/
        └── screens/
```

## Technologies

- **LocalStack**: AWS cloud simulation
- **Docker**: Containerization
- **Node.js**: Backend services
- **gRPC**: Microservices communication
- **Express**: REST API
- **Flutter**: Mobile application
- **AWS SDK**: Cloud service integration

## Points: 31

### Implementation Checklist
- [x] LocalStack configuration in Docker Compose
- [x] S3 bucket creation and configuration
- [x] DynamoDB table with GSI
- [x] SQS queue integration
- [x] SNS topic and subscriptions
- [x] Storage service (gRPC)
- [x] Task service (gRPC)
- [x] API Gateway with upload endpoint
- [x] Flutter mobile app
- [x] Camera integration
- [x] Image upload from mobile
- [x] Task creation with images
- [x] Validation scripts
- [x] Complete documentation

## License

MIT
