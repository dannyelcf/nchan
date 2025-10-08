#!/bin/bash
# Quick development helper script for the Nchan Docker environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    log_error "docker compose is not available. Please install Docker Compose V2"
    exit 1
fi

# Docker compose command with new file location
DOCKER_COMPOSE="docker compose -f docker/docker-compose.yml"

# Show usage
show_usage() {
    echo "Nchan Docker Development Helper"
    echo ""
    echo "Usage: ./dev.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [--rebuild]        Start the development environment"
    echo "  stop                     Stop the development environment"
    echo "  restart [--rebuild]      Restart the development environment"
    echo "  rebuild                  Rebuild nginx with nchan and restart"
    echo "  logs [service]           Show logs for all services or specific service"
    echo "  test                     Run basic functionality tests"
    echo "  bench                    Run comprehensive load testing suite"
    echo "  test-load-http           Run HTTP load testing only"
    echo "  test-load-ws             Run WebSocket load testing only"
    echo "  test-load-redis          Run Redis backend load testing only"
    echo "  cluster                  Start with Redis cluster"
    echo "  shell [service]          Get shell access to container"
    echo "  status                   Show status of all services"
    echo "  clean                    Clean up containers and volumes"
    echo ""
    echo "Load Testing Options:"
    echo "  Environment variables for load testing:"
    echo "    DURATION=30              Test duration in seconds (default: 30)"
    echo "    CONNECTIONS=50           Concurrent connections (default: 50)"
    echo ""
    echo "Examples:"
    echo "  ./dev.sh start --rebuild     # Start and rebuild nginx"
    echo "  ./dev.sh logs nchan          # Show nginx logs"
    echo "  ./dev.sh shell nchan         # Get shell in nchan container"
    echo "  ./dev.sh test                # Test basic pub/sub functionality"
    echo "  ./dev.sh bench               # Run comprehensive load tests"
    echo "  DURATION=60 ./dev.sh test-load-http  # HTTP load test for 60s"
}

# Start services
start_services() {
    local rebuild_flag=""
    if [[ "$1" == "--rebuild" ]]; then
        rebuild_flag="--env REBUILD=true"
    fi
    
    log_info "Starting Nchan development environment..."
    $DOCKER_COMPOSE up -d $rebuild_flag
    
    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 5
    
    # Check if nchan is responding
    if curl -f http://localhost:8080/health &>/dev/null; then
        log_success "Nchan is running and accessible at http://localhost:8080"
    else
        log_warning "Nchan may not be ready yet. Check logs with: ./dev.sh logs nchan"
    fi
}

# Stop services
stop_services() {
    log_info "Stopping Nchan development environment..."
    $DOCKER_COMPOSE down
    log_success "Services stopped"
}

# Restart services
restart_services() {
    local rebuild_flag=""
    if [[ "$1" == "--rebuild" ]]; then
        rebuild_flag="--env REBUILD=true"
    fi
    
    log_info "Restarting Nchan development environment..."
    $DOCKER_COMPOSE down
    $DOCKER_COMPOSE up -d $rebuild_flag
    log_success "Services restarted"
}

# Rebuild nginx
rebuild_nginx() {
    log_info "Rebuilding nginx with nchan..."
    $DOCKER_COMPOSE exec nchan /usr/src/build-nginx.sh
    $DOCKER_COMPOSE restart nchan
    log_success "Nginx rebuilt and restarted"
}

# Show logs
show_logs() {
    local service=${1:-""}
    if [[ -n "$service" ]]; then
        log_info "Showing logs for $service..."
        $DOCKER_COMPOSE logs -f $service
    else
        log_info "Showing logs for all services..."
        $DOCKER_COMPOSE logs -f
    fi
}

# Run basic tests
run_tests() {
    log_info "Running basic Nchan functionality tests..."
    
    # Test health endpoint
    if curl -f http://localhost:8080/health &>/dev/null; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        return 1
    fi
    
    # Test pub/sub
    local test_channel="test-$(date +%s)"
    local test_message="Hello from test at $(date)"
    
    log_info "Testing publish/subscribe with channel: $test_channel"
    
    # Publish message
    local pub_response=$(curl -s -X POST -d "$test_message" http://localhost:8080/pub/$test_channel)
    if [[ $? -eq 0 ]]; then
        log_success "Message published successfully"
        echo "Response: $pub_response"
    else
        log_error "Failed to publish message"
        return 1
    fi
    
    # Check channel stats
    local stats_response=$(curl -s http://localhost:8080/stats/$test_channel)
    if [[ $? -eq 0 ]]; then
        log_success "Channel stats retrieved"
        echo "Stats: $stats_response"
    else
        log_error "Failed to get channel stats"
        return 1
    fi
    
    # Test subscriber (with timeout)
    log_info "Testing subscriber (will timeout after 5 seconds)..."
    timeout 5 curl -s http://localhost:8080/sub/$test_channel || true
    
    log_success "Basic tests completed"
}

# Run load testing
run_bench() {
    log_info "Starting load testing environment..."
    $DOCKER_COMPOSE --profile loadtest up -d loadtest
    
    log_info "Running comprehensive load tests..."
    ./docker/test-load.sh
}

# Run HTTP load testing only
run_load_http() {
    log_info "Starting load testing environment..."
    $DOCKER_COMPOSE --profile loadtest up -d loadtest
    
    log_info "Running HTTP load tests..."
    $DOCKER_COMPOSE exec loadtest env DURATION=${DURATION:-30} CONNECTIONS=${CONNECTIONS:-50} /scripts/http-bench.sh
}

# Run WebSocket load testing only
run_load_ws() {
    log_info "Starting load testing environment..."
    $DOCKER_COMPOSE --profile loadtest up -d loadtest
    
    log_info "Running WebSocket load tests..."
    
    log_info "Testing WebSocket publishing..."
    $DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:8082 loadtest pub 50 0.1
    
    log_info "Testing WebSocket subscribing..."
    ($DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:8082 loadtest-sub sub 10 &) && \
    sleep 2 && \
    $DOCKER_COMPOSE exec loadtest python3 /scripts/websocket-test.py ws://nchan:8082 loadtest-sub pub 10 0.5
}

# Run Redis load testing only
run_load_redis() {
    log_info "Starting load testing environment..."
    $DOCKER_COMPOSE --profile loadtest up -d loadtest
    
    log_info "Running Redis backend load tests..."
    log_info "Testing Redis publishing performance..."
    $DOCKER_COMPOSE exec loadtest sh -c 'for i in $(seq 1 100); do curl -s -X POST -d "Redis load message $i" http://nchan:8081/redis-pub/redis-loadtest > /dev/null; done; echo "Published 100 messages to Redis backend"'
    
    log_info "Testing Redis subscribing..."
    $DOCKER_COMPOSE exec loadtest timeout 5s curl http://nchan:8081/redis-sub/redis-loadtest || echo "Redis subscribe test completed"
}

# Start with cluster
start_cluster() {
    log_info "Starting with Redis cluster..."
    $DOCKER_COMPOSE --profile cluster up -d
    log_success "Redis cluster started"
}

# Get shell access
get_shell() {
    local service=${1:-"nchan"}
    log_info "Getting shell access to $service container..."
    $DOCKER_COMPOSE exec $service bash
}

# Show status
show_status() {
    log_info "Service status:"
    $DOCKER_COMPOSE ps
    
    echo ""
    log_info "Health checks:"
    
    # Check nchan
    if curl -f http://localhost:8080/health &>/dev/null; then
        echo -e "  Nchan: ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  Nchan: ${RED}✗ Unhealthy${NC}"
    fi
    
    # Check redis
    if $DOCKER_COMPOSE exec redis redis-cli ping &>/dev/null; then
        echo -e "  Redis: ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  Redis: ${RED}✗ Unhealthy${NC}"
    fi
}

# Clean up
clean_up() {
    log_warning "This will remove all containers, networks, and volumes!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleaning up..."
        $DOCKER_COMPOSE down -v --remove-orphans
        docker system prune -f
        log_success "Cleanup completed"
    else
        log_info "Cleanup cancelled"
    fi
}

# Main command handling
case "${1:-""}" in
    "start")
        start_services $2
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        restart_services $2
        ;;
    "rebuild")
        rebuild_nginx
        ;;
    "logs")
        show_logs $2
        ;;
    "test")
        run_tests
        ;;
    "bench")
        run_bench
        ;;
    "test-load-http")
        run_load_http
        ;;
    "test-load-ws")
        run_load_ws
        ;;
    "test-load-redis")
        run_load_redis
        ;;
    "cluster")
        start_cluster
        ;;
    "shell")
        get_shell $2
        ;;
    "status")
        show_status
        ;;
    "clean")
        clean_up
        ;;
    "help"|"--help"|"-h"|"")
        show_usage
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac