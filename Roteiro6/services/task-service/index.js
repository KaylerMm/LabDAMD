const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, UpdateCommand, DeleteCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const PROTO_PATH = path.join(__dirname, 'task.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const taskProto = grpc.loadPackageDefinition(packageDefinition).task;

const dynamoClient = new DynamoDBClient({
  region: process.env.AWS_REGION || 'us-east-1',
  endpoint: process.env.AWS_ENDPOINT || 'http://localhost:4566',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test'
  }
});

const docClient = DynamoDBDocumentClient.from(dynamoClient);

const sqsClient = new SQSClient({
  region: process.env.AWS_REGION || 'us-east-1',
  endpoint: process.env.AWS_ENDPOINT || 'http://localhost:4566',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test'
  }
});

const snsClient = new SNSClient({
  region: process.env.AWS_REGION || 'us-east-1',
  endpoint: process.env.AWS_ENDPOINT || 'http://localhost:4566',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test'
  }
});

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'tasks';
const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL || 'http://localhost:4566/000000000000/task-queue';
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN || 'arn:aws:sns:us-east-1:000000000000:task-notifications';

async function sendToSQS(message) {
  try {
    const command = new SendMessageCommand({
      QueueUrl: SQS_QUEUE_URL,
      MessageBody: JSON.stringify(message)
    });
    await sqsClient.send(command);
  } catch (error) {
    console.error('SQS error:', error);
  }
}

async function publishToSNS(message) {
  try {
    const command = new PublishCommand({
      TopicArn: SNS_TOPIC_ARN,
      Message: JSON.stringify(message),
      Subject: 'Task Notification'
    });
    await snsClient.send(command);
  } catch (error) {
    console.error('SNS error:', error);
  }
}

async function createTask(call, callback) {
  try {
    const { user_id, title, description, image_key, image_url } = call.request;

    const task = {
      id: uuidv4(),
      userId: user_id,
      title,
      description,
      imageKey: image_key || '',
      imageUrl: image_url || '',
      completed: false,
      createdAt: Date.now(),
      updatedAt: Date.now()
    };

    const command = new PutCommand({
      TableName: TABLE_NAME,
      Item: task
    });

    await docClient.send(command);

    await sendToSQS({
      action: 'task_created',
      task
    });

    await publishToSNS({
      action: 'task_created',
      taskId: task.id,
      userId: task.userId,
      title: task.title
    });

    callback(null, {
      success: true,
      task: {
        id: task.id,
        user_id: task.userId,
        title: task.title,
        description: task.description,
        image_key: task.imageKey,
        image_url: task.imageUrl,
        completed: task.completed,
        created_at: task.createdAt,
        updated_at: task.updatedAt
      },
      message: 'Task created successfully'
    });
  } catch (error) {
    console.error('Create task error:', error);
    callback(null, {
      success: false,
      task: null,
      message: error.message
    });
  }
}

async function getTask(call, callback) {
  try {
    const { id } = call.request;

    const command = new GetCommand({
      TableName: TABLE_NAME,
      Key: { id }
    });

    const response = await docClient.send(command);

    if (!response.Item) {
      return callback(null, {
        success: false,
        task: null,
        message: 'Task not found'
      });
    }

    const task = response.Item;

    callback(null, {
      success: true,
      task: {
        id: task.id,
        user_id: task.userId,
        title: task.title,
        description: task.description,
        image_key: task.imageKey,
        image_url: task.imageUrl,
        completed: task.completed,
        created_at: task.createdAt,
        updated_at: task.updatedAt
      },
      message: 'Task retrieved successfully'
    });
  } catch (error) {
    console.error('Get task error:', error);
    callback(null, {
      success: false,
      task: null,
      message: error.message
    });
  }
}

async function updateTask(call, callback) {
  try {
    const { id, title, description, completed, image_key, image_url } = call.request;

    const updateExpression = [];
    const expressionAttributeNames = {};
    const expressionAttributeValues = {};

    if (title) {
      updateExpression.push('#title = :title');
      expressionAttributeNames['#title'] = 'title';
      expressionAttributeValues[':title'] = title;
    }

    if (description) {
      updateExpression.push('#description = :description');
      expressionAttributeNames['#description'] = 'description';
      expressionAttributeValues[':description'] = description;
    }

    if (completed !== undefined) {
      updateExpression.push('#completed = :completed');
      expressionAttributeNames['#completed'] = 'completed';
      expressionAttributeValues[':completed'] = completed;
    }

    if (image_key) {
      updateExpression.push('#imageKey = :imageKey');
      expressionAttributeNames['#imageKey'] = 'imageKey';
      expressionAttributeValues[':imageKey'] = image_key;
    }

    if (image_url) {
      updateExpression.push('#imageUrl = :imageUrl');
      expressionAttributeNames['#imageUrl'] = 'imageUrl';
      expressionAttributeValues[':imageUrl'] = image_url;
    }

    updateExpression.push('#updatedAt = :updatedAt');
    expressionAttributeNames['#updatedAt'] = 'updatedAt';
    expressionAttributeValues[':updatedAt'] = Date.now();

    const command = new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { id },
      UpdateExpression: `SET ${updateExpression.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
      ReturnValues: 'ALL_NEW'
    });

    const response = await docClient.send(command);
    const task = response.Attributes;

    await sendToSQS({
      action: 'task_updated',
      task
    });

    await publishToSNS({
      action: 'task_updated',
      taskId: task.id,
      userId: task.userId
    });

    callback(null, {
      success: true,
      task: {
        id: task.id,
        user_id: task.userId,
        title: task.title,
        description: task.description,
        image_key: task.imageKey,
        image_url: task.imageUrl,
        completed: task.completed,
        created_at: task.createdAt,
        updated_at: task.updatedAt
      },
      message: 'Task updated successfully'
    });
  } catch (error) {
    console.error('Update task error:', error);
    callback(null, {
      success: false,
      task: null,
      message: error.message
    });
  }
}

async function deleteTask(call, callback) {
  try {
    const { id } = call.request;

    const command = new DeleteCommand({
      TableName: TABLE_NAME,
      Key: { id }
    });

    await docClient.send(command);

    await sendToSQS({
      action: 'task_deleted',
      taskId: id
    });

    await publishToSNS({
      action: 'task_deleted',
      taskId: id
    });

    callback(null, {
      success: true,
      message: 'Task deleted successfully'
    });
  } catch (error) {
    console.error('Delete task error:', error);
    callback(null, {
      success: false,
      message: error.message
    });
  }
}

async function listTasks(call, callback) {
  try {
    const { user_id } = call.request;

    const command = new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'userId-index',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': user_id
      }
    });

    const response = await docClient.send(command);
    const tasks = response.Items || [];

    callback(null, {
      success: true,
      tasks: tasks.map(task => ({
        id: task.id,
        user_id: task.userId,
        title: task.title,
        description: task.description,
        image_key: task.imageKey,
        image_url: task.imageUrl,
        completed: task.completed,
        created_at: task.createdAt,
        updated_at: task.updatedAt
      })),
      message: 'Tasks listed successfully'
    });
  } catch (error) {
    console.error('List tasks error:', error);
    callback(null, {
      success: false,
      tasks: [],
      message: error.message
    });
  }
}

function main() {
  const server = new grpc.Server();
  
  server.addService(taskProto.TaskService.service, {
    CreateTask: createTask,
    GetTask: getTask,
    UpdateTask: updateTask,
    DeleteTask: deleteTask,
    ListTasks: listTasks
  });

  const port = process.env.PORT || '50052';
  server.bindAsync(
    `0.0.0.0:${port}`,
    grpc.ServerCredentials.createInsecure(),
    (error, port) => {
      if (error) {
        console.error('Failed to bind server:', error);
        return;
      }
      console.log(`Task service running on port ${port}`);
      server.start();
    }
  );
}

main();
