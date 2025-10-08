# Load Testing Scripts

This directory serves as documentation for the load testing setup. The actual scripts are located in `dev/bench/` and mounted via Docker volume.

## Script Sources

All load testing scripts are sourced from the existing `dev/bench/` directory:

- `websocket-test.py` → `dev/bench/websocket-test.py`
- `http-bench.sh` → `dev/bench/http-bench.sh`
- `publish.lua` → `dev/bench/publish.lua`
- `nchan_ws_test.py` → `dev/bench/nchan_ws_test.py`
- And many more comprehensive testing utilities

## Docker Integration

The loadtest container mounts `dev/bench/` as `/scripts/` via docker-compose volume:

```yaml
volumes:
  - ../dev/bench:/scripts
```

This ensures we use the existing, well-maintained scripts instead of creating duplicates.

## Available Scripts

The `dev/bench/` directory contains comprehensive testing utilities:

- **WebSocket Testing**: `websocket-test.py`, `nchan_ws_test.py`, `test-websocket-load.py`
- **HTTP Benchmarking**: `http-bench.sh`, `benchi.lua`
- **Redis Testing**: `redis-load.sh`, `redis-subscribe-test.sh`
- **Lua Scripts**: `publish.lua`, `cqb.lua`, `config.lua`
- **Advanced Tools**: `master.lua`, `slave.lua`, `publisher.lua`, `subscriber.lua`

## Usage Examples

```bash
# HTTP load testing
docker compose exec loadtest /scripts/http-bench.sh

# WebSocket publishing
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test pub 10 0.5

# WebSocket subscribing  
docker compose exec loadtest python3 /scripts/websocket-test.py ws://nchan:80 test sub 30

# Redis load testing
docker compose exec loadtest /scripts/redis-load.sh
```

## Development

When modifying scripts:

1. Edit the source files in `dev/bench/`
2. No copying needed - changes are immediately available via volume mount
3. Rebuild loadtest container if dependencies change: `docker compose build loadtest`
4. Test the changes

This approach maintains the single source of truth in `dev/bench/` while enabling Docker-based testing.
