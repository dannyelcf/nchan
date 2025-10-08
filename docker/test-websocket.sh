#!/bin/bash

# WebSocket testing script using Python
# Tests WebSocket pub/sub functionality
# Automatically detects dependencies and uses Docker mode when needed
#
# Usage:
#   ./test-websocket.sh              # Auto-detect mode (local or Docker)
#   ./test-websocket.sh --docker     # Force Docker mode
#   NCHAN_WS_HOST=host:port ./test-websocket.sh  # Custom host

# Docker compose command with correct file location
DOCKER_COMPOSE="docker compose -f $(dirname "$0")/docker-compose.yml"

NCHAN_WS_HOST=${NCHAN_WS_HOST:-localhost:8080}
TEST_CHANNEL=${TEST_CHANNEL:-ws_test_$(date +%s)}
DOCKER_MODE=false

# Auto-detect if we should use Docker mode
# Check if Python 3 and websockets module are available locally
if ! command -v python3 &> /dev/null || ! python3 -c "import websockets" 2>/dev/null; then
    echo "🐳 Local dependencies not available, automatically using Docker mode..."
    DOCKER_MODE=true
    NCHAN_WS_HOST="nchan:8082"
fi

# Allow manual override with --docker flag
if [[ "$1" == "--docker" ]]; then
    DOCKER_MODE=true
    NCHAN_WS_HOST="nchan:8082"
    shift
fi

# Path to the external WebSocket test script
SCRIPT_DIR="$(dirname "$0")"
WS_TEST_SCRIPT="$SCRIPT_DIR/nchan_ws_test.py"

echo "🚀 Starting WebSocket test..."
echo "Host: $NCHAN_WS_HOST"
echo "Channel: $TEST_CHANNEL"
echo

if [ "$DOCKER_MODE" = true ]; then
    echo "🐳 Running in Docker mode..."
    # Check if loadtest container is running
    if ! $DOCKER_COMPOSE ps --services --filter status=running | grep -q "loadtest"; then
        echo "🚀 Starting loadtest container..."
        $DOCKER_COMPOSE up -d loadtest
        sleep 2
    fi
    
    echo "📤 Testing WebSocket publishing (5 messages)..."
    $DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 "$TEST_CHANNEL" pub 5 0.5
    
    echo "📥 Testing WebSocket subscribing (5 seconds)..."
    $DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 "$TEST_CHANNEL" sub 5
    
    exit $?
fi

# Check if the external script exists (for local mode)
if [ "$DOCKER_MODE" = false ] && [ ! -f "$WS_TEST_SCRIPT" ]; then
    echo "❌ WebSocket test script not found: $WS_TEST_SCRIPT"
    echo "Please ensure the docker/nchan_ws_test.py file exists"
    echo "Falling back to Docker mode..."
    DOCKER_MODE=true
    NCHAN_WS_HOST="nchan:8082"
fi

if [ "$DOCKER_MODE" = false ]; then
    # Run the WebSocket test locally
    echo "🚀 Running WebSocket test locally..."
    python3 "$WS_TEST_SCRIPT" "$NCHAN_WS_HOST" "$TEST_CHANNEL"
fi