#!/bin/bash

echo "🚀 Starting Shopping List Messaging System Demo"
echo "=============================================="

echo "1. Starting infrastructure..."
docker-compose up -d

echo "2. Waiting for services to be ready..."
sleep 10

echo "3. Installing dependencies..."
npm install

echo "4. Starting services in background..."

echo "   Starting User Service..."
npm run start:user &
USER_PID=$!

echo "   Starting Item Service..."
npm run start:item &
ITEM_PID=$!

echo "   Starting List Service..."
npm run start:list &
LIST_PID=$!

sleep 5

echo "   Starting API Gateway..."
npm run start:gateway &
GATEWAY_PID=$!

echo "   Starting Notification Consumer..."
npm run start:notification-consumer &
NOTIFICATION_PID=$!

echo "   Starting Analytics Consumer..."
npm run start:analytics-consumer &
ANALYTICS_PID=$!

sleep 5

echo ""
echo "🎯 System is ready!"
echo "==================="
echo "RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "API Gateway: http://localhost:3000"
echo ""

echo "📝 Creating demo data..."

echo "Creating user..."
USER_RESPONSE=$(curl -s -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Demo User",
    "email": "demo@example.com"
  }')

USER_ID=$(echo $USER_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "User ID: $USER_ID"

echo "Creating items..."
APPLE_RESPONSE=$(curl -s -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Apple",
    "price": 1.50,
    "category": "Fruits"
  }')

APPLE_ID=$(echo $APPLE_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)

MILK_RESPONSE=$(curl -s -X POST http://localhost:3000/items \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Milk",
    "price": 2.99,
    "category": "Dairy"
  }')

MILK_ID=$(echo $MILK_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)

echo "Creating shopping list..."
LIST_RESPONSE=$(curl -s -X POST http://localhost:3000/lists \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Demo Shopping List\",
    \"userId\": \"$USER_ID\"
  }")

LIST_ID=$(echo $LIST_RESPONSE | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
echo "List ID: $LIST_ID"

echo "Adding items to list..."
curl -s -X POST http://localhost:3000/lists/$LIST_ID/items \
  -H "Content-Type: application/json" \
  -d "{
    \"itemId\": \"$APPLE_ID\",
    \"name\": \"Apple\",
    \"quantity\": 5,
    \"price\": 1.50
  }" > /dev/null

curl -s -X POST http://localhost:3000/lists/$LIST_ID/items \
  -H "Content-Type: application/json" \
  -d "{
    \"itemId\": \"$MILK_ID\",
    \"name\": \"Milk\",
    \"quantity\": 2,
    \"price\": 2.99
  }" > /dev/null

echo ""
echo "🎬 DEMO READY!"
echo "=============="
echo "To trigger the messaging demo, run:"
echo "curl -X POST http://localhost:3000/lists/$LIST_ID/checkout"
echo ""
echo "Watch the consumers' output for the messaging in action!"
echo ""
echo "To stop demo: ./stop-demo.sh"

function cleanup {
    echo ""
    echo "🛑 Stopping demo..."
    kill $USER_PID $ITEM_PID $LIST_PID $GATEWAY_PID $NOTIFICATION_PID $ANALYTICS_PID 2>/dev/null
    docker-compose down
    echo "Demo stopped!"
}

trap cleanup EXIT

echo "Press Ctrl+C to stop the demo"
wait