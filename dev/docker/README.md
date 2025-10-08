# Nchan Development Environment

A comprehensive Docker-based development environment for Nchan using Debian, supporting Ruby, Lua, C, and Bash development with all existing dev scripts.

## 🚀 Quick Start

```bash
# Navigate to the dev/docker directory
cd dev/docker

# Build and start the environment
make build
make up

# Enter the development shell
make shell
```

## 📁 Directory Structure

```
dev/docker/
├── Dockerfile           # Debian-based development image
├── docker-compose.yml   # Container orchestration
├── Makefile            # Centralized command interface
└── README.md           # This documentation
```

## 🐳 Docker Services

### nchan-dev (Main Development Container)
- **Purpose**: Primary development environment
- **Base**: Debian bookworm-slim
- **Tools**: Ruby, Lua, C compiler, build tools, Python
- **Access**: `make shell`

### nginx (Testing Server)
- **Purpose**: Nginx server for testing Nchan
- **Ports**: 8080:80, 8081:8081, 8082:8082
- **Access**: `make nginx-shell`

### redis (Backend Storage)
- **Purpose**: Redis backend for Nchan testing
- **Port**: 6379:6379
- **Access**: `make redis-cli`

### loadtest (Load Testing)
- **Purpose**: Dedicated container for benchmarking
- **Tools**: wrk, artillery, Python tools
- **Access**: `make loadtest-shell`

## 🛠️ Installed Development Tools

### Build & Compile
- **C/C++**: gcc, make, cmake, build-essential
- **Ruby**: ruby, bundler, gem
- **Lua**: lua5.2, luarocks
- **Python**: python3, pip3

### Nginx Dependencies
- libssl-dev, libpcre3-dev, zlib1g-dev (from existing prepare.sh)
- Ruby XML/XSLT dependencies: libxslt-dev, libxml2-dev

### Testing & Benchmarking
- **HTTP Testing**: wrk, artillery
- **WebSocket Testing**: Python WebSocket tools
- **Ruby Testing**: minitest, existing test suite

### Development Utilities
- vim, emacs-nox, nano (editors)
- htop, lsof, strace (monitoring)
- git, curl, wget (network tools)
- redis-tools, netcat, telnet (networking)

## 📋 Available Make Commands

### 🐳 Docker Operations
```bash
make build         # Build all Docker images
make up            # Start all services  
make down          # Stop all services
make clean         # Remove containers and volumes
make rebuild       # Rebuild and restart services
```

### 🖥️ Development Shells
```bash
make shell         # Enter main development container
make nginx-shell   # Enter nginx container
make loadtest-shell # Enter load testing container
```

### 🔧 Build & Setup (Uses Existing Scripts)
```bash
make prepare       # Install dependencies (./prepare.sh)
make rebuild-nginx # Rebuild nginx with nchan (./rebuild.sh)
make bundle-install # Install Ruby gems
```

### 🚀 Nginx Operations (Uses Existing nginx.sh)
```bash
make nginx-start   # Start nginx server
make nginx-stop    # Stop nginx server
make nginx-reload  # Reload configuration
make nginx-status  # Check status
make nginx-logs    # Show logs
```

### 🧪 Testing (Uses Existing Test Scripts)
```bash
make test          # Run basic tests (test.rb)
make test-parallel # Run parallel tests (test-parallel.sh)
make test-websocket # Run WebSocket tests (wstest.py)
make ruby-test     # Run Ruby test suite
```

### ⚡ Benchmarking (Uses Existing Bench Scripts)
```bash
make bench         # Comprehensive benchmark suite
make bench-http    # HTTP benchmarks (bench/http-bench.sh)
make bench-parallel # Parallel benchmarks (bench-parallel.sh)
make bench-lua     # Lua benchmarks (bench/benchi.lua)
make pressure      # Pressure testing (pressure.rb)
make flood         # Flood testing (flood.rb)
```

### 📡 Pub/Sub Testing (Uses Existing Scripts)
```bash
make pub           # Start publisher (pub.rb)
make sub           # Start subscriber (sub.rb)
make pub-multi     # Multi-publisher test (pub-multi.rb)
```

### 🔍 Debugging (Uses Existing Scripts)
```bash
make debug         # Debug session (debug.sh)
make examine-core  # Examine core dumps (examine_coredump.sh)
make multiconn     # Multi-connection tests (multiconn.sh)
```

### 🔗 Redis Operations
```bash
make redis-cli     # Connect to Redis CLI
make redis-logs    # Show Redis logs
```

## 📦 Volume Mounts

The Docker containers mount existing dev scripts for maximum reuse:

```yaml
volumes:
  - ..:/app:rw              # Dev directory (all scripts)
  - ../../src:/app/src:rw   # Source code
  - ../../:/app/project:rw  # Project root
```

## 🎯 Key Features

### ✅ Script Reuse
- **100% Reuse**: All existing dev scripts are mounted and accessible
- **No Duplication**: Uses existing prepare.sh, rebuild.sh, nginx.sh, test.rb, etc.
- **Consistent Environment**: Same scripts work in Docker and locally

### ✅ Debian-Based
- **Stable Base**: Debian bookworm-slim for reliability
- **Package Management**: APT for consistent dependency installation
- **Security**: Regular security updates through Debian

### ✅ Multi-Language Support
- **Ruby**: Full Ruby development with bundler and gems
- **Lua**: Lua 5.2 with luarocks package manager
- **C/C++**: GCC compiler with full build tools
- **Python**: Python 3 with pip for additional tools

### ✅ Development Workflow
- **Make Interface**: Centralized commands through Makefile
- **Live Reload**: Volume mounts for real-time code changes
- **Multi-Container**: Separate containers for different concerns
- **Easy Debugging**: Direct shell access to all containers

## 🔄 Development Workflow

1. **Setup**: `make build && make up`
2. **Develop**: `make shell` to enter development environment
3. **Test**: `make test` to run test suite
4. **Benchmark**: `make bench` to run performance tests
5. **Debug**: `make debug` for debugging sessions

## 🧹 Cleanup

```bash
make down          # Stop all services
make clean         # Remove containers and volumes
```

## 🔧 Customization

### Environment Variables
Customize behavior through environment variables in docker-compose.yml:

```yaml
environment:
  - NCHAN_HOST=nginx:80
  - REDIS_HOST=redis
  - REDIS_PORT=6379
  - DEVELOPMENT=1
```

### Port Mapping
Modify ports in docker-compose.yml as needed:

```yaml
ports:
  - "8080:80"    # Nginx HTTP
  - "8081:8081"  # Nginx Redis
  - "8082:8082"  # Nginx WebSocket
  - "6379:6379"  # Redis
```

## 🤝 Integration with Existing Scripts

This Docker environment is designed to work seamlessly with all existing dev scripts:

- **prepare.sh**: Dependency installation (adapted for Debian)
- **rebuild.sh**: Nginx compilation with nchan
- **nginx.sh**: Nginx server management
- **test.rb**: Ruby test suite
- **bench/**: All benchmarking scripts
- **pressure.rb, flood.rb**: Load testing
- **pub.rb, sub.rb**: Pub/Sub testing

All scripts maintain their original functionality while running in a consistent Docker environment.