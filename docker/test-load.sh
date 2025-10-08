#!/bin/bash

# Comprehensive Load Testing Suite for Nchan
set -e

# Docker compose command with correct file location
DOCKER_COMPOSE="docker compose -f $(dirname "$0")/docker-compose.yml"

NCHAN_HOST=${NCHAN_HOST:-localhost:8080}
WS_HOST=${WS_HOST:-localhost:8082}
REDIS_HOST=${REDIS_HOST:-localhost:8081}
DURATION=${DURATION:-30}
CONNECTIONS=${CONNECTIONS:-50}

echo "🚀 Nchan Load Testing Suite"
echo "============================="
echo "Host: $NCHAN_HOST"
echo "WebSocket Host: $WS_HOST"
echo "Redis Host: $REDIS_HOST"
echo "Duration: ${DURATION}s"
echo "Connections: $CONNECTIONS"
echo

# Check if loadtest container is running, start if needed
if ! $DOCKER_COMPOSE ps --services --filter status=running | grep -q "loadtest"; then
    echo "🚀 Starting loadtest container..."
    $DOCKER_COMPOSE up -d loadtest
    sleep 3
fi

echo "1️⃣ HTTP Load Testing..."
echo "========================"
$DOCKER_COMPOSE exec loadtest bash /scripts/http-bench.sh "$NCHAN_HOST" 100 10

echo
echo "2️⃣ WebSocket Load Testing..."
echo "============================"
echo "Starting WebSocket subscriber..."
($DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 loadtest sub 10 &) && \
    sleep 3 && \
    $DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 loadtest pub 5 1

echo
echo "3️⃣ Redis Backend Load Testing..."
echo "================================="
echo "Testing Redis publishing performance..."
$DOCKER_COMPOSE exec loadtest lua /scripts/publish.lua http://nchan:8081/redis-pub/ redis-load-test 100

echo
echo "🎉 Load testing completed!"
        return 1
    fi
    echo
}

# Test 1: HTTP Endpoints Load Test
echo "🔧 Test 1: HTTP Endpoints Performance"
echo "-------------------------------------"
run_load_test "HTTP Load Test" "env DURATION=$DURATION CONNECTIONS=$CONNECTIONS /scripts/http-bench.sh"

# Test 2: WebSocket Load Test
echo "🔧 Test 2: WebSocket Performance"
echo "--------------------------------"
if $DOCKER_COMPOSE ps | grep nchan-loadtest >/dev/null; then
    echo "📤 Testing WebSocket publishing..."
    run_load_test "WebSocket Publish" "python3 /scripts/websocket-test.py ws://nchan:8082 loadtest pub 20 0.2"
    
    echo "📥 Testing WebSocket subscribing..."
    (docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:8082 loadtest sub 10 &) && \
    sleep 2 && \
    docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:8082 loadtest pub 5 1
else
    echo "⚠️  Load testing container not available, skipping WebSocket tests"
fi

# Test 3: Redis Backend Load Test
echo "🔧 Test 3: Redis Backend Performance"
echo "------------------------------------"
echo "📤 Testing Redis publishing performance..."
redis_pub_cmd="wrk -t8 -c$CONNECTIONS -d${DURATION}s --latency -H 'Content-Type: text/plain' --script <(echo 'wrk.method=\"POST\"; wrk.body=\"Redis load test message\"') http://nchan:8081/redis-pub/redis-loadtest"

# Simplified Redis test using external script
run_load_test "Redis Publishing" "/scripts/redis-load.sh"

echo "📥 Testing Redis subscribing..."
run_load_test "Redis Subscribe Test" "/scripts/redis-subscribe-test.sh"

# Test 4: Mixed Load Test
echo "🔧 Test 4: Mixed Protocol Load Test"
echo "-----------------------------------"
echo "Testing concurrent HTTP, WebSocket, and Redis operations..."

# Start background subscribers
echo "Starting background subscribers..."
(timeout 20s curl -s http://nchan:80/sub/mixed-test > /tmp/http-sub.log &)
(timeout 20s curl -s http://nchan:8081/redis-sub/mixed-test > /tmp/redis-sub.log &)

sleep 2

# Publish via different protocols
echo "Publishing via HTTP..."
for i in $(seq 1 10); do
    curl -s -X POST -d "HTTP message $i" http://nchan:80/pub/mixed-test > /dev/null
    sleep 0.5
done

echo "Publishing via Redis..."
for i in $(seq 1 10); do
    curl -s -X POST -d "Redis message $i" http://nchan:8081/redis-pub/mixed-test > /dev/null
    sleep 0.5
done

sleep 3
echo "✅ Mixed protocol test completed"

# Test 5: Stress Test
echo "🔧 Test 5: High-Load Stress Test"
echo "--------------------------------"
STRESS_CONNECTIONS=$((CONNECTIONS * 2))
STRESS_DURATION=15

echo "Running high-load stress test with $STRESS_CONNECTIONS connections for ${STRESS_DURATION}s..."
run_load_test "Stress Test" "env DURATION=$STRESS_DURATION CONNECTIONS=$STRESS_CONNECTIONS /scripts/http-bench.sh"

# Summary
echo "🎉 Load Testing Suite Completed!"
echo "================================="
echo "All tests have been executed. Check the results above for performance metrics."
echo
echo "📋 Test Summary:"
echo "  ✅ HTTP endpoint load testing"
echo "  ✅ WebSocket performance testing"
echo "  ✅ Redis backend load testing"
echo "  ✅ Mixed protocol testing"
echo "  ✅ High-load stress testing"
echo
echo "💡 Tips for production:"
echo "  - Monitor response times under load"
echo "  - Check memory usage during stress tests"
echo "  - Test with realistic message sizes"
echo "  - Consider connection pooling for high loads"
echo "  - Monitor Redis performance if using Redis backend"
echo
echo "🔧 To run individual tests:"
echo "  ./dev.sh test-load-http    # HTTP load test only"
echo "  ./dev.sh test-load-ws      # WebSocket test only" 
echo "  ./dev.sh test-load-redis   # Redis backend test only"