# 🚀 Nchan Docker Development Environment

A comprehensive Docker-based development environment for the [Nchan](https://nchan.io) pub/sub module for nginx, built with nginx-1.29.2.

## � Quick Start

```bash
# Start the development environment
./dev.sh start

# Test basic functionality
./test-nchan.sh

# Open your browser to http://localhost:8080
```

## ✅ Current Status

**✅ Working Features:**
- ✅ nginx-1.29.2 with Nchan module compiled and running
- ✅ Basic pub/sub functionality (`/pub/{channel}`, `/sub/{channel}`)
- ✅ WebSocket support (`/ws/{channel}`)
- ✅ Channel statistics (`/stats/{channel}`)
- ✅ Global statistics (`/nchan_stats`)
- ✅ Development helper scripts
- ✅ Automated testing tools
- ✅ Redis server (available for future integration)

**⚠️ Known Limitations:**
- ⚠️ Redis integration temporarily disabled due to configuration conflicts
- ⚠️ Load testing environment available but not fully tested

## 🛠️ What's Included

### **Main Services:**
- **nchan** - nginx-1.29.2 with Nchan module compiled and ready (Port: 8080)
- **redis** - Redis server for future Redis-backed channels (Port: 6379)

### **Available Endpoints:**
- `http://localhost:8080` - Main web interface with testing tools
- `http://localhost:8080/pub/{channel}` - Publish to channel
- `http://localhost:8080/sub/{channel}` - Subscribe to channel  
- `http://localhost:8080/pubsub/{channel}` - Combined pub/sub endpoint
- `http://localhost:8080/ws/{channel}` - WebSocket endpoint
- `http://localhost:8080/nchan_stats` - Performance statistics
- `http://localhost:8080/stats/{channel}` - Per-channel statistics

## 📁 Project Structure

```
/
├── Dockerfile                    # Main development container
├── Dockerfile.loadtest          # Load testing container
├── docker-compose.yml           # Orchestration configuration
├── dev/
│   ├── nginx-configs/           # Additional nginx configurations
│   │   ├── redis-channels.conf # Redis-backed channels
│   │   ├── websocket.conf       # WebSocket configurations
│   │   └── monitoring.conf      # Performance monitoring
│   └── ...                     # Other development files
└── logs/                        # Nginx logs (created on start)
```

## 🔧 Available Services

### Main Services

- **nchan** (localhost:8080): Main Nchan development environment
- **redis** (localhost:6379): Redis server for testing Redis-backed channels

### Development Profiles

Enable additional services with Docker Compose profiles:

```bash
# Start with Redis cluster
docker compose --profile cluster up -d

# Start with development tools
docker compose --profile tools up -d

# Start with load testing tools
docker compose --profile loadtest up -d

# Start everything
docker compose --profile cluster --profile tools --profile loadtest up -d
```

## 🌐 Available Endpoints

### Main Container (Port 8080)
- `POST /pub/{channel}` - Publish messages
- `GET /sub/{channel}` - Subscribe to messages (long-polling)
- `GET|POST /pubsub/{channel}` - Combined pub/sub endpoint
- `GET /stats/{channel}` - Channel statistics
- `GET /nchan_stats` - Global Nchan statistics
- `GET /health` - Health check endpoint

### Additional Configurations (when mounted)
- **Port 8081**: Redis-backed channels (`/redis-pub/`, `/redis-sub/`, `/redis-pubsub/`)
- **Port 8082**: WebSocket endpoints (`/ws/`, `/sse/`, `/multi/`)
- **Port 8083**: Monitoring and performance testing (`/status`, `/events/`, `/perf-*`)

## 🛠️ Development Workflow

### Making Code Changes

1. **Edit the Nchan source code** (the current directory is mounted as `/usr/src/nchan`)

2. **Rebuild and restart nginx:**
   ```bash
   docker compose exec nchan /usr/src/build-nginx.sh
   docker compose restart nchan
   ```

   Or set the `REBUILD` environment variable to automatically rebuild on start:
   ```bash
   docker compose up -d --env REBUILD=true
   ```

3. **View logs:**
   ```bash
   docker compose logs -f nchan
   ```

### Testing Different Configurations

1. **Add custom nginx configuration:**
   ```bash
   # Create a new .conf file in dev/nginx-configs/
   echo 'server { listen 8090; location / { return 200 "Custom config!"; } }' > dev/nginx-configs/custom.conf
   
   # Restart to load the configuration
   docker compose restart nchan
   ```

2. **Test with Redis:**
   ```bash
   # Redis is automatically available at redis:6379 from within containers
   curl -X POST -d "Redis message" http://localhost:8081/redis-pub/test
   curl http://localhost:8081/redis-sub/test
   ```

## 🧪 Testing and Benchmarking

### Load Testing

Start the load testing container:
```bash
docker compose --profile loadtest up -d loadtest
```

Run HTTP benchmarks:
```bash
docker compose exec loadtest /scripts/http-bench.sh
```

Test WebSocket connections:
```bash
# Publish 100 messages with 0.1s delay
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test pub 100 0.1

# Subscribe for 30 seconds
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test sub 30
```

### Redis Cluster Testing

Start Redis cluster:
```bash
docker compose --profile cluster up -d
```

The cluster will be automatically configured with 3 nodes. Update your nginx configuration to use:
```nginx
nchan_redis_server redis-cluster-1:7001 redis-cluster-2:7002 redis-cluster-3:7003;
```

## 🐛 Debugging

### View Logs
```bash
# Nginx logs
docker compose logs -f nchan

# Redis logs
docker compose logs -f redis

# All logs
docker compose logs -f
```

### Access Container Shell
```bash
# Main development container
docker compose exec nchan bash

# Redis CLI
docker compose exec redis redis-cli

# Load testing tools
docker compose exec loadtest sh
```

### Debug nginx Configuration
```bash
# Test nginx configuration
docker compose exec nchan nginx -t

# Reload nginx
docker compose exec nchan nginx -s reload

# Check nginx processes
docker compose exec nchan ps aux | grep nginx
```

## 📊 Monitoring and Metrics

### Built-in Status Pages
- http://localhost:8080/nchan_stats - Basic Nchan statistics
- http://localhost:8083/status - Detailed monitoring (if monitoring.conf is loaded)

### Channel Events (Debugging)
Enable channel events in your configuration:
```nginx
location ~ /pub/(.*)$ {
    nchan_publisher;
    nchan_channel_id $1;
    nchan_channel_events_channel_id $1;  # Enable events
}
```

Subscribe to events:
```bash
curl http://localhost:8083/events/your_channel_id
```

## 🔄 Advanced Usage

### Custom nginx Configuration

1. **Override the main configuration:**
   ```bash
   # Copy the existing config and modify
   docker compose exec nchan cp /etc/nginx/nginx.conf ./custom-nginx.conf
   
   # Edit custom-nginx.conf, then mount it
   # Add to docker-compose.yml volumes:
   # - ./custom-nginx.conf:/etc/nginx/nginx.conf
   ```

2. **Add include files:**
   ```bash
   # Place .conf files in dev/nginx-configs/ (automatically mounted)
   ```

### Environment Variables

- `REBUILD=true` - Rebuild nginx with nchan on container start
- `NCHAN_HOST` - Host for load testing (default: nchan:80)
- `CHANNEL` - Default channel for testing (default: test)
- `DURATION` - Load test duration (default: 30)
- `CONNECTIONS` - Concurrent connections for load testing (default: 100)

### Persistent Data

Redis data is automatically persisted in Docker volumes. To reset:
```bash
docker compose down -v  # Remove volumes
docker compose up -d    # Recreate with fresh data
```

## 🆘 Troubleshooting

### Common Issues

1. **nginx fails to start:**
   ```bash
   # Check configuration syntax
   docker compose exec nchan nginx -t
   
   # Check error logs
   docker compose logs nchan
   ```

2. **Can't connect to Redis:**
   ```bash
   # Verify Redis is running
   docker compose exec redis redis-cli ping
   
   # Check network connectivity
   docker compose exec nchan nc -zv redis 6379
   ```

3. **Module not found:**
   ```bash
   # Rebuild nginx with nchan
   docker compose exec nchan /usr/src/build-nginx.sh
   docker compose restart nchan
   ```

4. **Permission issues:**
   ```bash
   # Check file ownership
   docker compose exec nchan ls -la /var/log/nginx/
   
   # Fix permissions (if needed)
   docker compose exec nchan chown -R nginx:nginx /var/log/nginx/
   ```

### Getting Help

1. **Check nginx version and modules:**
   ```bash
   docker compose exec nchan nginx -V
   ```

2. **Verify nchan is loaded:**
   ```bash
   docker compose exec nchan nginx -V 2>&1 | grep nchan
   ```

3. **View detailed error information:**
   ```bash
   # Set debug level in nginx.conf
   error_log /var/log/nginx/error.log debug;
   
   # Restart and check logs
   docker compose restart nchan
   docker compose logs -f nchan
   ```

## 📚 Next Steps

- Read the [Nchan documentation](https://nchan.io) for advanced configuration options
- Explore the example configurations in `dev/nginx-configs/`
- Try the WebSocket client at `/` in your browser
- Set up your IDE to work with the mounted source code
- Implement custom testing scenarios using the load testing tools

Happy developing! 🎉