#!/bin/bash

echo "=== Stopping Roteiro 6 Services ==="
echo ""

if [ -f /tmp/roteiro6-pids.txt ]; then
    echo "Stopping Node.js services..."
    while read pid; do
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid 2>/dev/null
            echo "✓ Stopped process $pid"
        fi
    done < /tmp/roteiro6-pids.txt
    rm /tmp/roteiro6-pids.txt
else
    echo "Stopping all Node.js services..."
    pkill -f "node.*storage-service" 2>/dev/null
    pkill -f "node.*task-service" 2>/dev/null
    pkill -f "node.*api-gateway" 2>/dev/null
fi

echo ""
echo "Stopping LocalStack..."
if command -v localstack &> /dev/null; then
    localstack stop
    echo "✓ LocalStack stopped"
else
    echo "LocalStack CLI not found"
fi

echo ""
echo "✅ All services stopped!"
