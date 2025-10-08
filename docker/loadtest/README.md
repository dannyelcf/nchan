# Load Testing Scripts

This directory contains externalized scripts for load testing the Nchan environment.

## Files

### `websocket-test.py`
- **Purpose**: WebSocket load testing script
- **Usage**: `python3 websocket-test.py <uri> <channel> <pub|sub> [args...]`
- **Features**:
  - Publish messages to WebSocket channels
  - Subscribe to WebSocket channels
  - Configurable message count and delay

### `http-bench.sh`
- **Purpose**: HTTP endpoint benchmarking using wrk
- **Usage**: Called via environment variables
- **Environment Variables**:
  - `NCHAN_HOST` - Target host (default: nchan:80)
  - `CHANNEL` - Channel name (default: test)  
  - `DURATION` - Test duration in seconds (default: 30)
  - `CONNECTIONS` - Concurrent connections (default: 100)
  - `RATE` - Target request rate (default: 1000)

### `publish.lua`
- **Purpose**: Lua script for wrk to simulate publishing
- **Features**: Generates sequential test messages with timestamps

## Integration

These scripts are copied to both:
1. `/scripts/` in the Docker container during build
2. `dev/bench/` directory (mounted as `/scripts` in loadtest container)

The mounting strategy ensures the scripts are available for load testing while maintaining externalized source files.

## Usage Examples

```bash
# HTTP load testing
docker compose exec loadtest /scripts/http-bench.sh

# WebSocket publishing
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test pub 10 0.5

# WebSocket subscribing  
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test sub 30
```

## Development

When modifying these scripts:
1. Edit the source files in `docker/loadtest/`
2. Copy changes to `dev/bench/`: `cp docker/loadtest/* dev/bench/`
3. Rebuild loadtest container: `docker compose build loadtest`
4. Test the changes