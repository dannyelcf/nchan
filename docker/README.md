# Docker Files Structure

This directory contains all the external Docker-related files that were previously embedded inline in the Dockerfile using `COPY <<EOF` syntax.

## Files Overview

### `build-nginx.sh`
- **Purpose**: Build script for compiling nginx with the Nchan module
- **Usage**: Called during Docker build and available for manual rebuilds
- **Features**: 
  - Configures nginx with all necessary modules
  - Compiles with optimized settings
  - Creates symlink for easy access
  - Displays build information

### `nginx.conf`
- **Purpose**: Main nginx configuration for the development environment
- **Features**:
  - Basic pub/sub endpoints (`/pub/*`, `/sub/*`, `/pubsub/*`)
  - Channel statistics endpoints
  - Health check endpoint
  - Static content serving
  - Debug logging enabled

### `index.html`
- **Purpose**: Welcome page and testing interface
- **Features**:
  - Overview of available endpoints
  - Quick test examples with curl commands
  - Development workflow instructions
  - Links to documentation

### `docker-entrypoint.sh`
- **Purpose**: Container startup script with graceful shutdown handling
- **Features**:
  - Creates necessary directories
  - Sets proper permissions
  - Handles rebuild requests via `REBUILD` environment variable
  - Tests configuration before starting
  - Graceful shutdown on SIGTERM/SIGINT

### `test-websocket-load.py`

- **Purpose**: Advanced WebSocket load testing utility
- **Features**:
  - Asynchronous WebSocket publishing and subscribing
  - Configurable message count and delay
  - Real-time message tracking with timestamps
  - Support for both publishing and subscribing modes
  - Error handling and connection management
- **Usage**:
  - Publishing: `python3 test-websocket-load.py ws://host:port channel pub 10 0.1`
  - Subscribing: `python3 test-websocket-load.py ws://host:port channel sub 30`

### `nchan_ws_test.py`

- **Purpose**: Externalized WebSocket integration test (from test-websocket.sh)
- **Features**:
  - WebSocket publisher and subscriber integration
  - HTTP-to-WebSocket message flow testing
  - Real-time message tracking with timestamps
  - Automatic connection management
- **Usage**:
  - Auto-mode: `./test-websocket.sh` (automatically detects local dependencies)
  - Local: `python3 nchan_ws_test.py host:port channel` (requires websockets module)
  - Docker: `./test-websocket.sh --docker` (force Docker mode)
- **Note**: The integration script runs indefinitely until interrupted (Ctrl+C)
- **Smart Detection**: The test-websocket.sh wrapper automatically uses Docker mode when local Python dependencies are not available

## Benefits of Externalization

1. **Better Maintainability**: Each file can be edited separately with proper syntax highlighting
2. **Version Control**: Individual file changes are tracked clearly in git
3. **Reusability**: Scripts can be used outside of Docker builds
4. **Testing**: Individual components can be tested in isolation
5. **Readability**: Dockerfile is cleaner and easier to understand

## Usage in Dockerfile

The Dockerfile now uses simple `COPY` commands:

```dockerfile
# Copy and set up build script
COPY docker/build-nginx.sh /usr/src/build-nginx.sh
RUN chmod +x /usr/src/build-nginx.sh

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy HTML page for testing
COPY docker/index.html /usr/share/nginx/html/index.html

# Copy and set up entrypoint script
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
```

## Development Workflow

When making changes to these files:

1. Edit the file in the `docker/` directory
2. Rebuild the container: `./dev.sh rebuild`
3. Test the changes: `./dev.sh test`

For configuration changes that don't require a rebuild:

- `nginx.conf` changes: Restart nginx with `docker compose exec nchan nginx -s reload`
- `index.html` changes: Refresh the browser (changes are immediate)
