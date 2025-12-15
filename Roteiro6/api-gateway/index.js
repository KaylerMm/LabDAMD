const express = require('express');
const cors = require('cors');
const multer = require('multer');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

const upload = multer({ storage: multer.memoryStorage() });

const STORAGE_PROTO_PATH = path.join(__dirname, '../services/storage-service/storage.proto');
const TASK_PROTO_PATH = path.join(__dirname, '../services/task-service/task.proto');

const storagePackageDefinition = protoLoader.loadSync(STORAGE_PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const taskPackageDefinition = protoLoader.loadSync(TASK_PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const storageProto = grpc.loadPackageDefinition(storagePackageDefinition).storage;
const taskProto = grpc.loadPackageDefinition(taskPackageDefinition).task;

const storageClient = new storageProto.StorageService(
  process.env.STORAGE_SERVICE_URL || 'localhost:50051',
  grpc.credentials.createInsecure()
);

const taskClient = new taskProto.TaskService(
  process.env.TASK_SERVICE_URL || 'localhost:50052',
  grpc.credentials.createInsecure()
);

app.post('/api/upload', upload.single('image'), (req, res) => {
  try {
    const { userId, taskId } = req.body;
    let imageData;
    let contentType = 'image/jpeg';

    if (req.file) {
      imageData = req.file.buffer.toString('base64');
      contentType = req.file.mimetype;
    } else if (req.body.imageData) {
      imageData = req.body.imageData;
      contentType = req.body.contentType || 'image/jpeg';
    } else {
      return res.status(400).json({ error: 'No image provided' });
    }

    storageClient.UploadImage({
      image_data: imageData,
      content_type: contentType,
      user_id: userId,
      task_id: taskId
    }, (error, response) => {
      if (error) {
        console.error('Upload error:', error);
        return res.status(500).json({ error: error.message });
      }

      res.json(response);
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/images/:key(*)', (req, res) => {
  const imageKey = req.params.key;

  storageClient.GetImageUrl({ image_key: imageKey }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.delete('/api/images/:key(*)', (req, res) => {
  const imageKey = req.params.key;

  storageClient.DeleteImage({ image_key: imageKey }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.get('/api/images', (req, res) => {
  const prefix = req.query.prefix || '';

  storageClient.ListImages({ prefix }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.post('/api/tasks', (req, res) => {
  const { userId, title, description, imageKey, imageUrl } = req.body;

  taskClient.CreateTask({
    user_id: userId,
    title,
    description,
    image_key: imageKey || '',
    image_url: imageUrl || ''
  }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.get('/api/tasks/:id', (req, res) => {
  taskClient.GetTask({ id: req.params.id }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.put('/api/tasks/:id', (req, res) => {
  const { title, description, completed, imageKey, imageUrl } = req.body;

  taskClient.UpdateTask({
    id: req.params.id,
    title,
    description,
    completed,
    image_key: imageKey,
    image_url: imageUrl
  }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.delete('/api/tasks/:id', (req, res) => {
  taskClient.DeleteTask({ id: req.params.id }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.get('/api/tasks', (req, res) => {
  const userId = req.query.userId;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  taskClient.ListTasks({ user_id: userId }, (error, response) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json(response);
  });
});

app.post('/api/tasks-with-image', upload.single('image'), async (req, res) => {
  try {
    const { userId, title, description } = req.body;
    
    if (!req.file && !req.body.imageData) {
      return res.status(400).json({ error: 'Image is required' });
    }

    let imageData;
    let contentType = 'image/jpeg';

    if (req.file) {
      imageData = req.file.buffer.toString('base64');
      contentType = req.file.mimetype;
    } else {
      imageData = req.body.imageData;
      contentType = req.body.contentType || 'image/jpeg';
    }

    const taskId = require('crypto').randomUUID();

    storageClient.UploadImage({
      image_data: imageData,
      content_type: contentType,
      user_id: userId,
      task_id: taskId
    }, (uploadError, uploadResponse) => {
      if (uploadError || !uploadResponse.success) {
        return res.status(500).json({ 
          error: uploadError ? uploadError.message : uploadResponse.message 
        });
      }

      taskClient.CreateTask({
        user_id: userId,
        title,
        description,
        image_key: uploadResponse.image_key,
        image_url: uploadResponse.image_url
      }, (taskError, taskResponse) => {
        if (taskError || !taskResponse.success) {
          return res.status(500).json({ 
            error: taskError ? taskError.message : taskResponse.message 
          });
        }

        res.json({
          success: true,
          task: taskResponse.task,
          message: 'Task created with image successfully'
        });
      });
    });
  } catch (error) {
    console.error('Create task with image error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});
