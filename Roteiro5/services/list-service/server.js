const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoose = require('mongoose');
const MessageBroker = require('../../shared/message-broker');
require('dotenv').config();

const app = express();
const PORT = 3002;
const messageBroker = new MessageBroker();

app.use(helmet());
app.use(cors());
app.use(express.json());

const listItemSchema = new mongoose.Schema({
  itemId: { type: String, required: true },
  name: { type: String, required: true },
  quantity: { type: Number, required: true, default: 1 },
  price: { type: Number, required: true },
  completed: { type: Boolean, default: false }
});

const listSchema = new mongoose.Schema({
  title: { type: String, required: true },
  userId: { type: String, required: true },
  items: [listItemSchema],
  status: { type: String, enum: ['active', 'completed'], default: 'active' },
  totalAmount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now },
  completedAt: Date
});

const List = mongoose.model('List', listSchema);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'list-service' });
});

app.get('/lists', async (req, res) => {
  try {
    const lists = await List.find();
    res.json(lists);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/lists/:id', async (req, res) => {
  try {
    const list = await List.findById(req.params.id);
    if (!list) {
      return res.status(404).json({ error: 'List not found' });
    }
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/lists', async (req, res) => {
  try {
    const list = new List(req.body);
    await list.save();
    res.status(201).json(list);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.put('/lists/:id', async (req, res) => {
  try {
    const list = await List.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!list) {
      return res.status(404).json({ error: 'List not found' });
    }
    res.json(list);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/lists/:id/items', async (req, res) => {
  try {
    const list = await List.findById(req.params.id);
    if (!list) {
      return res.status(404).json({ error: 'List not found' });
    }
    
    list.items.push(req.body);
    list.totalAmount = list.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    await list.save();
    
    res.status(201).json(list);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

app.post('/lists/:id/checkout', async (req, res) => {
  try {
    const list = await List.findById(req.params.id);
    if (!list) {
      return res.status(404).json({ error: 'List not found' });
    }
    
    if (list.status === 'completed') {
      return res.status(400).json({ error: 'List already completed' });
    }

    list.status = 'completed';
    list.completedAt = new Date();
    list.totalAmount = list.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    await list.save();

    const checkoutEvent = {
      listId: list._id,
      userId: list.userId,
      totalAmount: list.totalAmount,
      itemsCount: list.items.length,
      completedAt: list.completedAt
    };

    await messageBroker.publish('list.checkout.completed', checkoutEvent);
    
    res.status(202).json({ 
      message: 'Checkout initiated successfully',
      listId: list._id,
      status: 'processing'
    });
  } catch (error) {
    console.error('Checkout error:', error);
    res.status(500).json({ error: error.message });
  }
});

app.delete('/lists/:id', async (req, res) => {
  try {
    const list = await List.findByIdAndDelete(req.params.id);
    if (!list) {
      return res.status(404).json({ error: 'List not found' });
    }
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

async function startServer() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    await messageBroker.connect();
    console.log('Connected to RabbitMQ');
    
    app.listen(PORT, () => {
      console.log(`List Service running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start List Service:', error);
    process.exit(1);
  }
}

process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  await messageBroker.close();
  process.exit(0);
});

startServer();