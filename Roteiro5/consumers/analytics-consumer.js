const MessageBroker = require('../shared/message-broker');
require('dotenv').config();

class AnalyticsConsumer {
  constructor() {
    this.messageBroker = new MessageBroker();
    this.dailyStats = {
      totalRevenue: 0,
      ordersCount: 0,
      averageOrderValue: 0,
      date: new Date().toDateString()
    };
  }

  async start() {
    try {
      await this.messageBroker.connect();
      console.log('Analytics Consumer started');
      
      await this.messageBroker.createConsumer(
        process.env.ANALYTICS_QUEUE || 'analytics',
        'list.checkout.#',
        this.handleCheckoutEvent.bind(this)
      );
      
      console.log('Listening for checkout events for analytics...');
      this.startPeriodicReport();
    } catch (error) {
      console.error('Failed to start Analytics Consumer:', error);
      process.exit(1);
    }
  }

  async handleCheckoutEvent(event) {
    try {
      console.log('Processing checkout analytics:', event);
      
      this.updateDailyStats(event);
      
      console.log('📊 Analytics updated:');
      console.log(`   - Order value: $${event.totalAmount.toFixed(2)}`);
      console.log(`   - Items purchased: ${event.itemsCount}`);
      console.log(`   - Daily revenue: $${this.dailyStats.totalRevenue.toFixed(2)}`);
      console.log(`   - Orders today: ${this.dailyStats.ordersCount}`);
      console.log(`   - Average order: $${this.dailyStats.averageOrderValue.toFixed(2)}`);
      
      await this.simulateDashboardUpdate();
      
      console.log('✅ Dashboard updated successfully');
    } catch (error) {
      console.error('Error processing checkout analytics:', error);
      throw error;
    }
  }

  updateDailyStats(event) {
    const today = new Date().toDateString();
    
    if (this.dailyStats.date !== today) {
      this.resetDailyStats(today);
    }
    
    this.dailyStats.totalRevenue += event.totalAmount;
    this.dailyStats.ordersCount += 1;
    this.dailyStats.averageOrderValue = this.dailyStats.totalRevenue / this.dailyStats.ordersCount;
  }

  resetDailyStats(date) {
    this.dailyStats = {
      totalRevenue: 0,
      ordersCount: 0,
      averageOrderValue: 0,
      date
    };
    console.log(`📅 Reset daily stats for ${date}`);
  }

  async simulateDashboardUpdate() {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve();
      }, 200 + Math.random() * 800);
    });
  }

  startPeriodicReport() {
    setInterval(() => {
      if (this.dailyStats.ordersCount > 0) {
        console.log('\n📈 Periodic Analytics Report:');
        console.log(`   Date: ${this.dailyStats.date}`);
        console.log(`   Total Revenue: $${this.dailyStats.totalRevenue.toFixed(2)}`);
        console.log(`   Orders Count: ${this.dailyStats.ordersCount}`);
        console.log(`   Average Order Value: $${this.dailyStats.averageOrderValue.toFixed(2)}`);
        console.log('');
      }
    }, 30000);
  }

  async stop() {
    await this.messageBroker.close();
    console.log('Analytics Consumer stopped');
  }
}

const consumer = new AnalyticsConsumer();

process.on('SIGINT', async () => {
  console.log('Shutting down Analytics Consumer...');
  await consumer.stop();
  process.exit(0);
});

consumer.start();