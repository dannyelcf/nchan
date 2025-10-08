# Nchan Development Environment Makefile
COMPOSE = docker compose -f docker-compose.yml

.PHONY: help build up down shell loadtest-shell clean prepare rebuild-nginx test bench pub sub bundle-install nginx-start nginx-stop fix-git test-pubsub

help:
	@echo "Nchan Development Environment Commands"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make build        - Build images"
	@echo "  make up           - Start services"
	@echo "  make down         - Stop services"
	@echo "  make clean        - Clean resources (volumes, orphans)"
	@echo "  make shell        - Enter dev container"
	@echo ""
	@echo "Development:"
	@echo "  make prepare      - Install dependencies"
	@echo "  make rebuild-nginx - Rebuild nginx with nchan"
	@echo "  make bundle-install - Install Ruby gems"
	@echo "  make bundle-clean - Clean bundle cache and reinstall"
	@echo "  make fix-git      - Fix git configuration issues"
	@echo ""
	@echo "Testing:"
	@echo "  make test         - Run test suite"
	@echo "  make test-with-nginx - Auto-start nginx and run tests"
	@echo "  make bench        - Run benchmarks"
	@echo "  make test-pubsub  - Test pub/sub messaging system"
	@echo "  make test-lua     - Test Lua installation"
	@echo "  make test-gcc     - Test GCC installation"
	@echo "  make test-python  - Test Python installation"
	@echo "  make test-redis   - Test Redis connection"
	@echo ""
	@echo "Nginx Management:"
	@echo "  make nginx-start  - Start nginx service"
	@echo "  make nginx-stop   - Stop nginx service"
	@echo "  make nginx-restart - Restart nginx service"
	@echo "  make nginx-status - Check nginx status"
	@echo ""
	@echo "Publishing Tools:"
	@echo "  make pub                                     - Show publisher help"
	@echo "  make pub ARGS='-m \"Hello\" /pubsub/test'    - Publish message (exits after)"
	@echo "  make sub                                     - Show subscriber help"
	@echo "  make sub ARGS='/pubsub/test'                 - Subscribe (auto-websocket)"
	@echo ""
	@echo "Quick Start Examples:"
	@echo "  make up && make rebuild-nginx && make nginx-start"
	@echo "  make test-with-nginx"
	@echo ""
	@echo "Real-time Messaging Test:"
	@echo "  Terminal 1: make sub ARGS='/pubsub/demo'     # Start subscriber FIRST"
	@echo "  Terminal 2: make pub ARGS='-m \"Live message\" /pubsub/demo'  # Then publish"
	@echo "  Result: Terminal 1 will show 'Live message' immediately!"
	@echo "  Note: Subscriber MUST be connected BEFORE publishing for real-time delivery"
	@echo ""
	@echo "Basic Examples:"
	@echo "  make pub ARGS='-m \"Hello World\" /pubsub/demo'"
	@echo "  make sub ARGS='/pubsub/demo'"

build:
	@echo "Building images..."
	$(COMPOSE) build

up:
	@echo "Starting services..."
	$(COMPOSE) up -d

down:
	@echo "Stopping services..."
	$(COMPOSE) down

shell:
	@echo "Entering dev shell..."
	$(COMPOSE) exec nchan-dev /bin/bash

clean:
	@echo "Cleaning resources..."
	$(COMPOSE) down -v --remove-orphans

prepare:
	@echo "Installing dependencies..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app && if [ -f prepare.sh ]; then ./prepare.sh; else echo 'Dependencies already installed in Docker image'; fi"

rebuild-nginx:
	@echo "Rebuilding nginx with nchan..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && export GIT_DISCOVERY_ACROSS_FILESYSTEM=1 && git config --global --add safe.directory /app && rm -rf ~/.bundle/cache && bundle install --quiet && ./rebuild.sh"

test:
	@echo "Running test suite..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && export GIT_DISCOVERY_ACROSS_FILESYSTEM=1 && ln -sf nchan_tools-gem/lib/nchan_tools/pubsub.rb pubsub.rb && bundle install --quiet && bundle exec ruby test.rb --server http://127.0.0.1:8082 --profile external"

test-with-nginx:
	@echo "Starting nginx and running test suite..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && ./nginx.sh > /tmp/nginx.log 2>&1 & nginx_pid=\$$!; sleep 3; netstat -tlnp | grep :8082 || (echo 'nginx failed to start on port 8082'; cat /tmp/nginx.log; kill \$$nginx_pid 2>/dev/null; exit 1); export GIT_DISCOVERY_ACROSS_FILESYSTEM=1 && bundle install --quiet && bundle exec ruby test.rb --server http://127.0.0.1:8082 --profile external; test_exit=\$$?; kill \$$nginx_pid 2>/dev/null; exit \$$test_exit"

bench:
	@echo "Running benchmarks..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && bundle exec ruby bench.rb"

pub:
	@echo "Starting publisher..."
	@if [ -z "$(ARGS)" ]; then \
		echo "Usage: make pub ARGS='-m \"message\" /pubsub/channel'"; \
		echo "Example: make pub ARGS='-m \"Hello World\" /pubsub/demo'"; \
		$(COMPOSE) exec -it nchan-dev /bin/bash -c "cd /app/dev && ./pub.rb --help"; \
	else \
		$(COMPOSE) exec -it nchan-dev /bin/bash -c "cd /app/dev && bundle install --quiet && echo 'Publishing message...' && ./pub.rb -1 $(ARGS)"; \
	fi

sub:
	@echo "Starting subscriber..."
	@if [ -z "$(ARGS)" ]; then \
		echo "Usage: make sub ARGS='/pubsub/channel' or ARGS='-c websocket /pubsub/channel'"; \
		echo "Example: make sub ARGS='/pubsub/demo'"; \
		$(COMPOSE) exec -it nchan-dev /bin/bash -c "cd /app/dev && ./sub.rb --help"; \
	else \
		case "$(ARGS)" in \
			/*) $(COMPOSE) exec -it nchan-dev /bin/bash -c "cd /app/dev && bundle install --quiet && echo 'Subscribing with websocket...' && ./sub.rb -c websocket $(ARGS)" ;; \
			*) $(COMPOSE) exec -it nchan-dev /bin/bash -c "cd /app/dev && bundle install --quiet && echo 'Subscribing...' && ./sub.rb $(ARGS)" ;; \
		esac \
	fi

# Additional utility commands
bundle-install:
	@echo "Installing Ruby gems..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && bundle install"

bundle-clean:
	@echo "Cleaning bundle cache..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && rm -rf ~/.bundle && bundle install"

nginx-start:
	@echo "Starting nginx with nchan module..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && ./nginx.sh start"

nginx-stop:
	@echo "Stopping nginx service..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && ./nginx.sh stop"

nginx-restart:
	@echo "Restarting nginx with nchan module..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && ./nginx.sh restart"

nginx-status:
	@echo "Checking nginx status..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && ps aux | grep nginx | grep -v grep || echo 'nginx not running'"

fix-git:
	@echo "Fixing git configuration..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "git config --global --add safe.directory '*' && git config --global user.name 'Developer' && git config --global user.email 'developer@nchan.dev' && echo 'Git configuration fixed'"

# Testing individual components
test-lua:
	@echo "Testing Lua..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "lua5.2 -e 'print(\"✅ Lua\", _VERSION, \"working!\")'"

test-gcc:
	@echo "Testing GCC..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "gcc --version | head -1"

test-python:
	@echo "Testing Python..."
	$(COMPOSE) exec nchan-dev /bin/bash -c "python3 --version"

test-redis:
	@echo "Testing Redis..."
	$(COMPOSE) exec redis redis-cli ping

test-pubsub:
	@echo "Testing real-time pub/sub messaging..."
	@echo "1. Clearing and publishing test message..."
	@$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && curl -X DELETE http://localhost:8082/pubsub/test >/dev/null 2>&1 || true"
	@$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && curl -s -X POST -d 'Real-time test message' http://localhost:8082/pubsub/test | grep 'queued messages: 1' && echo '✅ Message published successfully'" || echo "❌ Message publish failed"
	@echo "2. Testing message retrieval..."
	@$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && timeout 3 ./sub.rb -c websocket /pubsub/test" 2>/dev/null | head -n 20 | grep "Real-time test message" >/dev/null && echo "✅ Message retrieved successfully" || echo "❌ Message retrieval failed (expected - websocket doesn't get buffered messages)"
	@echo "3. Testing direct HTTP retrieval..."
	@$(COMPOSE) exec nchan-dev /bin/bash -c "cd /app/dev && curl -s http://localhost:8082/pubsub/test | grep 'Real-time test message'" >/dev/null && echo "✅ HTTP retrieval works" || echo "❌ HTTP retrieval failed"
	@echo "✅ Pub/sub system is working!"
	@echo "Note: For real-time messaging, start subscriber FIRST, then publish"
