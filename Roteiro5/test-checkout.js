const axios = require('axios');

async function testCheckout() {
  const baseUrl = 'http://localhost:3000';
  
  try {
    console.log('🧪 Testing Shopping List Checkout Flow');
    console.log('=====================================');

    console.log('1. Creating test user...');
    const userResponse = await axios.post(`${baseUrl}/users`, {
      name: 'Test User',
      email: `test-${Date.now()}@example.com`
    });
    const userId = userResponse.data._id;
    console.log(`✓ User created: ${userId}`);

    console.log('2. Creating test items...');
    const breadResponse = await axios.post(`${baseUrl}/items`, {
      name: 'Bread',
      price: 3.99,
      category: 'Bakery'
    });
    
    const cheeseResponse = await axios.post(`${baseUrl}/items`, {
      name: 'Cheese',
      price: 5.49,
      category: 'Dairy'
    });
    
    console.log(`✓ Items created: Bread, Cheese`);

    console.log('3. Creating shopping list...');
    const listResponse = await axios.post(`${baseUrl}/lists`, {
      title: 'Test Shopping List',
      userId: userId
    });
    const listId = listResponse.data._id;
    console.log(`✓ List created: ${listId}`);

    console.log('4. Adding items to list...');
    await axios.post(`${baseUrl}/lists/${listId}/items`, {
      itemId: breadResponse.data._id,
      name: 'Bread',
      quantity: 2,
      price: 3.99
    });

    await axios.post(`${baseUrl}/lists/${listId}/items`, {
      itemId: cheeseResponse.data._id,
      name: 'Cheese',
      quantity: 1,
      price: 5.49
    });
    
    console.log('✓ Items added to list');

    console.log('5. Performing checkout...');
    const startTime = Date.now();
    
    const checkoutResponse = await axios.post(`${baseUrl}/lists/${listId}/checkout`);
    
    const endTime = Date.now();
    const responseTime = endTime - startTime;
    
    console.log(`✅ Checkout completed!`);
    console.log(`   Response time: ${responseTime}ms`);
    console.log(`   Status: ${checkoutResponse.status} ${checkoutResponse.statusText}`);
    console.log(`   Message: ${checkoutResponse.data.message}`);
    console.log('');
    console.log('🔍 Watch the consumer terminals for messaging activity!');
    console.log('📊 Check RabbitMQ Management at http://localhost:15672');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
  }
}

if (require.main === module) {
  testCheckout();
}

module.exports = testCheckout;