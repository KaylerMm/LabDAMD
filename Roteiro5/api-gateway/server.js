const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

const services = {
  user: process.env.USER_SERVICE_URL || 'http://localhost:3001',
  list: process.env.LIST_SERVICE_URL || 'http://localhost:3002',
  item: process.env.ITEM_SERVICE_URL || 'http://localhost:3003'
};

app.use(helmet());
app.use(cors());
app.use(express.json());

const forwardRequest = async (req, res, serviceUrl, path) => {
  try {
    const url = `${serviceUrl}${path}`;
    const response = await axios({
      method: req.method,
      url,
      data: req.body,
      params: req.query,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    res.status(response.status).json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      console.error('Gateway error:', error.message);
      res.status(503).json({ error: 'Service unavailable' });
    }
  }
};

app.get('/health', async (req, res) => {
  try {
    const healthChecks = await Promise.allSettled([
      axios.get(`${services.user}/health`),
      axios.get(`${services.list}/health`),
      axios.get(`${services.item}/health`)
    ]);

    const results = healthChecks.map((check, index) => ({
      service: Object.keys(services)[index],
      status: check.status === 'fulfilled' ? 'ok' : 'error',
      url: Object.values(services)[index]
    }));

    const allHealthy = results.every(r => r.status === 'ok');
    
    res.status(allHealthy ? 200 : 503).json({
      gateway: 'ok',
      services: results
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.all('/users*', (req, res) => {
  const path = req.path.replace('/users', '/users');
  forwardRequest(req, res, services.user, path);
});

app.all('/lists*', (req, res) => {
  const path = req.path.replace('/lists', '/lists');
  forwardRequest(req, res, services.list, path);
});

app.all('/items*', (req, res) => {
  const path = req.path.replace('/items', '/items');
  forwardRequest(req, res, services.item, path);
});

app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
  console.log('Service endpoints:');
  Object.entries(services).forEach(([name, url]) => {
    console.log(`  ${name}: ${url}`);
  });
});