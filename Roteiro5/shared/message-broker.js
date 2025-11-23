const amqp = require('amqplib');

class MessageBroker {
  constructor() {
    this.connection = null;
    this.channel = null;
    this.exchangeName = process.env.EXCHANGE_NAME || 'shopping_events';
  }

  async connect() {
    try {
      this.connection = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://localhost:5672');
      this.channel = await this.connection.createChannel();
      
      await this.channel.assertExchange(this.exchangeName, 'topic', { durable: true });
      
      console.log('Connected to RabbitMQ');
      return true;
    } catch (error) {
      console.error('Failed to connect to RabbitMQ:', error);
      return false;
    }
  }

  async publish(routingKey, message) {
    if (!this.channel) {
      throw new Error('Not connected to RabbitMQ');
    }

    const messageBuffer = Buffer.from(JSON.stringify({
      ...message,
      timestamp: new Date().toISOString(),
      id: require('uuid').v4()
    }));

    return this.channel.publish(this.exchangeName, routingKey, messageBuffer, {
      persistent: true
    });
  }

  async createConsumer(queueName, routingKey, callback) {
    if (!this.channel) {
      throw new Error('Not connected to RabbitMQ');
    }

    await this.channel.assertQueue(queueName, { durable: true });
    await this.channel.bindQueue(queueName, this.exchangeName, routingKey);
    
    this.channel.prefetch(1);
    
    return this.channel.consume(queueName, async (msg) => {
      if (msg) {
        try {
          const content = JSON.parse(msg.content.toString());
          await callback(content);
          this.channel.ack(msg);
        } catch (error) {
          console.error('Error processing message:', error);
          this.channel.nack(msg, false, false);
        }
      }
    });
  }

  async close() {
    if (this.connection) {
      await this.connection.close();
    }
  }
}

module.exports = MessageBroker;