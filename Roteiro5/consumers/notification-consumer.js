const MessageBroker = require('../shared/message-broker');
const axios = require('axios');
require('dotenv').config();

class NotificationConsumer {
  constructor() {
    this.messageBroker = new MessageBroker();
    this.userServiceUrl = process.env.USER_SERVICE_URL || 'http://localhost:3001';
  }

  async start() {
    try {
      await this.messageBroker.connect();
      console.log('Notification Consumer started');
      
      await this.messageBroker.createConsumer(
        process.env.NOTIFICATION_QUEUE || 'notifications',
        'list.checkout.#',
        this.handleCheckoutEvent.bind(this)
      );
      
      console.log('Listening for checkout events...');
    } catch (error) {
      console.error('Failed to start Notification Consumer:', error);
      process.exit(1);
    }
  }

  async handleCheckoutEvent(event) {
    try {
      console.log('Processing checkout notification:', event);
      
      const userEmail = await this.getUserEmail(event.userId);
      
      console.log(`📧 Sending receipt for list ${event.listId} to user ${userEmail}`);
      console.log(`   - Total amount: $${event.totalAmount.toFixed(2)}`);
      console.log(`   - Items count: ${event.itemsCount}`);
      console.log(`   - Completed at: ${event.completedAt}`);
      
      await this.simulateEmailSending();
      
      console.log(`✅ Receipt sent successfully to ${userEmail}`);
    } catch (error) {
      console.error('Error processing checkout notification:', error);
      throw error;
    }
  }

  async getUserEmail(userId) {
    try {
      const response = await axios.get(`${this.userServiceUrl}/users/${userId}`);
      return response.data.email;
    } catch (error) {
      console.warn(`Could not fetch user ${userId}, using placeholder email`);
      return `user-${userId}@example.com`;
    }
  }

  async simulateEmailSending() {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve();
      }, 100 + Math.random() * 500);
    });
  }

  async stop() {
    await this.messageBroker.close();
    console.log('Notification Consumer stopped');
  }
}

const consumer = new NotificationConsumer();

process.on('SIGINT', async () => {
  console.log('Shutting down Notification Consumer...');
  await consumer.stop();
  process.exit(0);
});

consumer.start();