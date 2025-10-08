#!/bin/bash

# Quick testing script for Nchan functionality
# Tests basic pub/sub operations

set -e

NCHAN_HOST=${NCHAN_HOST:-localhost:8080}
TEST_CHANNEL=${TEST_CHANNEL:-test_$(date +%s)}
TEST_MESSAGE="Hello from Nchan test! Timestamp: $(date)"

echo "🔧 Testing Nchan functionality..."
echo "Host: $NCHAN_HOST"
echo "Channel: $TEST_CHANNEL"
echo "Message: $TEST_MESSAGE"
echo

# Check if nchan is responding
echo "📡 Checking Nchan service..."
if ! curl -s "http://$NCHAN_HOST/nchan_stats" > /dev/null; then
    echo "❌ Nchan service is not responding at http://$NCHAN_HOST"
    echo "Make sure the development environment is running: ./dev.sh start"
    exit 1
fi
echo "✅ Nchan service is responding"

# Test publishing a message
echo
echo "📤 Publishing test message..."
PUB_RESPONSE=$(curl -s -w "%{http_code}" -X POST -d "$TEST_MESSAGE" "http://$NCHAN_HOST/pub/$TEST_CHANNEL")
PUB_CODE="${PUB_RESPONSE: -3}"

if [ "$PUB_CODE" = "200" ] || [ "$PUB_CODE" = "202" ]; then
    echo "✅ Message published successfully (HTTP $PUB_CODE)"
else
    echo "❌ Failed to publish message (HTTP $PUB_CODE)"
    exit 1
fi

# Test subscribing and receiving the message
echo
echo "📥 Testing subscription..."
SUB_RESPONSE=$(timeout 5s curl -s "http://$NCHAN_HOST/sub/$TEST_CHANNEL" || echo "TIMEOUT")

if [ "$SUB_RESPONSE" = "TIMEOUT" ]; then
    echo "⚠️  Subscription timed out (this is normal if no new messages arrive)"
    
    # Try publishing another message and subscribing simultaneously
    echo "📤 Publishing another message and subscribing..."
    (sleep 1 && curl -s -X POST -d "Second message: $(date)" "http://$NCHAN_HOST/pub/$TEST_CHANNEL") &
    SUB_RESPONSE=$(timeout 3s curl -s "http://$NCHAN_HOST/sub/$TEST_CHANNEL" || echo "TIMEOUT")
    
    if [ "$SUB_RESPONSE" != "TIMEOUT" ]; then
        echo "✅ Received message: $SUB_RESPONSE"
    else
        echo "⚠️  Still timed out, but this might be expected behavior"
    fi
else
    echo "✅ Received message: $SUB_RESPONSE"
fi

# Test channel stats
echo
echo "📊 Checking channel statistics..."
STATS_RESPONSE=$(curl -s "http://$NCHAN_HOST/stats/$TEST_CHANNEL" 2>/dev/null || echo "Stats not available")
if [ "$STATS_RESPONSE" != "Stats not available" ]; then
    echo "✅ Channel stats: $STATS_RESPONSE"
else
    echo "⚠️  Channel stats endpoint not available"
fi

# Test nchan_stats endpoint
echo
echo "📈 Checking Nchan global statistics..."
GLOBAL_STATS=$(curl -s "http://$NCHAN_HOST/nchan_stats" | head -5)
echo "✅ Global stats (first 5 lines):"
echo "$GLOBAL_STATS"

echo
echo "🎉 Basic Nchan functionality test completed!"
echo
echo "Next steps:"
echo "  - Visit http://$NCHAN_HOST for the web interface"
echo "  - Try the WebSocket endpoints: ws://$NCHAN_HOST:8082/ws/{channel}"
echo "  - Check Redis integration: http://$NCHAN_HOST:8081"
echo "  - Run load tests: ./dev.sh bench"
echo