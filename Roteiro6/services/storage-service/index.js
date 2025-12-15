const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const PROTO_PATH = path.join(__dirname, 'storage.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const storageProto = grpc.loadPackageDefinition(packageDefinition).storage;

const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-east-1',
  endpoint: process.env.AWS_ENDPOINT || 'http://localhost:4566',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test'
  },
  forcePathStyle: true
});

const BUCKET_NAME = process.env.S3_BUCKET || 'shopping-images';

async function uploadImage(call, callback) {
  try {
    const { image_data, content_type, user_id, task_id } = call.request;

    if (!image_data) {
      return callback(null, {
        success: false,
        image_key: '',
        image_url: '',
        message: 'Image data is required'
      });
    }

    const buffer = Buffer.from(image_data, 'base64');
    const extension = content_type ? content_type.split('/')[1] : 'jpg';
    const imageKey = `${user_id}/${task_id}/${uuidv4()}.${extension}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: imageKey,
      Body: buffer,
      ContentType: content_type || 'image/jpeg',
      Metadata: {
        userId: user_id,
        taskId: task_id
      }
    });

    await s3Client.send(command);

    const imageUrl = `${process.env.AWS_ENDPOINT}/${BUCKET_NAME}/${imageKey}`;

    callback(null, {
      success: true,
      image_key: imageKey,
      image_url: imageUrl,
      message: 'Image uploaded successfully'
    });
  } catch (error) {
    console.error('Upload error:', error);
    callback(null, {
      success: false,
      image_key: '',
      image_url: '',
      message: error.message
    });
  }
}

async function getImageUrl(call, callback) {
  try {
    const { image_key } = call.request;

    const imageUrl = `${process.env.AWS_ENDPOINT}/${BUCKET_NAME}/${image_key}`;

    callback(null, {
      success: true,
      image_url: imageUrl,
      message: 'Image URL retrieved successfully'
    });
  } catch (error) {
    console.error('Get URL error:', error);
    callback(null, {
      success: false,
      image_url: '',
      message: error.message
    });
  }
}

async function deleteImage(call, callback) {
  try {
    const { image_key } = call.request;

    const command = new DeleteObjectCommand({
      Bucket: BUCKET_NAME,
      Key: image_key
    });

    await s3Client.send(command);

    callback(null, {
      success: true,
      message: 'Image deleted successfully'
    });
  } catch (error) {
    console.error('Delete error:', error);
    callback(null, {
      success: false,
      message: error.message
    });
  }
}

async function listImages(call, callback) {
  try {
    const { prefix } = call.request;

    const command = new ListObjectsV2Command({
      Bucket: BUCKET_NAME,
      Prefix: prefix || ''
    });

    const response = await s3Client.send(command);
    const imageKeys = response.Contents ? response.Contents.map(obj => obj.Key) : [];

    callback(null, {
      success: true,
      image_keys: imageKeys,
      message: 'Images listed successfully'
    });
  } catch (error) {
    console.error('List error:', error);
    callback(null, {
      success: false,
      image_keys: [],
      message: error.message
    });
  }
}

function main() {
  const server = new grpc.Server();
  
  server.addService(storageProto.StorageService.service, {
    UploadImage: uploadImage,
    GetImageUrl: getImageUrl,
    DeleteImage: deleteImage,
    ListImages: listImages
  });

  const port = process.env.PORT || '50051';
  server.bindAsync(
    `0.0.0.0:${port}`,
    grpc.ServerCredentials.createInsecure(),
    (error, port) => {
      if (error) {
        console.error('Failed to bind server:', error);
        return;
      }
      console.log(`Storage service running on port ${port}`);
      server.start();
    }
  );
}

main();
