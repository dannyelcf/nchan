# Dockerfile for Nchan development environment
# Based on Ubuntu 24.04 with nginx-1.29.2

FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /usr/src

# Update sources and install basic tools first
RUN apt-get update && apt-get install -y ca-certificates curl wget gnupg lsb-release

# Install system dependencies and build tools
RUN apt-get install -y \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Nginx dependencies
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    libxslt1-dev \
    libgd-dev \
    libgeoip-dev \
    libxml2-dev \
    # Additional libraries that might be needed
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libffi-dev \
    liblzma-dev \
    # Ruby dependencies
    libyaml-dev \
    # Development and debugging tools
    git \
    vim \
    nano \
    htop \
    strace \
    gdb \
    valgrind \
    # Ruby and dependencies for nchan tools
    ruby \
    ruby-dev \
    bundler \
    # Lua for testing
    lua5.2 \
    # Network tools
    netcat-openbsd \
    telnet \
    # Process management
    supervisor \
    # Redis client for testing
    redis-tools \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install specific Ruby gems globally that are commonly used in nchan development
RUN gem install \
    nokogiri \
    websocket-client-simple \
    json \
    eventmachine \
    thin

# Set up nginx user and directories
RUN groupadd -r nginx && useradd -r -g nginx nginx

# Create necessary directories
RUN mkdir -p /var/log/nginx \
    /var/cache/nginx \
    /etc/nginx/conf.d \
    /usr/local/nginx \
    /var/run/nginx

# Download and extract nginx-1.29.2 source
RUN wget -O nginx-1.29.2.tar.gz "http://nginx.org/download/nginx-1.29.2.tar.gz" \
    && tar -xzf nginx-1.29.2.tar.gz \
    && rm nginx-1.29.2.tar.gz

# Create nchan directory
RUN mkdir -p /usr/src/nchan

# Copy the nchan source code
COPY . /usr/src/nchan/

# Set working directory to nchan for development
WORKDIR /usr/src/nchan

# Install Ruby dependencies for nchan development tools (optional)
RUN if [ -f "dev/Gemfile" ]; then \
        cd dev && bundle install --without development test || echo "Warning: Some Ruby gems failed to install"; \
    fi

# Build script that can be used to rebuild nginx with nchan
COPY <<EOF /usr/src/build-nginx.sh
#!/bin/bash
set -e

echo "Building nginx with nchan module..."

cd /usr/src/nginx-1.29.2

# Clean previous build if exists
make clean 2>/dev/null || true

# Configure nginx with nchan module
./configure \\
    --prefix=/usr/local/nginx \\
    --sbin-path=/usr/local/nginx/sbin/nginx \\
    --conf-path=/etc/nginx/nginx.conf \\
    --error-log-path=/var/log/nginx/error.log \\
    --http-log-path=/var/log/nginx/access.log \\
    --pid-path=/var/run/nginx/nginx.pid \\
    --lock-path=/var/run/nginx/nginx.lock \\
    --http-client-body-temp-path=/var/cache/nginx/client_temp \\
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \\
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \\
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \\
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \\
    --user=nginx \\
    --group=nginx \\
    --with-http_ssl_module \\
    --with-http_realip_module \\
    --with-http_addition_module \\
    --with-http_sub_module \\
    --with-http_dav_module \\
    --with-http_flv_module \\
    --with-http_mp4_module \\
    --with-http_gunzip_module \\
    --with-http_gzip_static_module \\
    --with-http_random_index_module \\
    --with-http_secure_link_module \\
    --with-http_stub_status_module \\
    --with-http_auth_request_module \\
    --with-threads \\
    --with-stream \\
    --with-stream_ssl_module \\
    --with-stream_realip_module \\
    --with-http_slice_module \\
    --with-file-aio \\
    --with-http_v2_module \\
    --with-debug \\
    --add-module=/usr/src/nchan

# Build nginx
make -j\$(nproc)

# Install nginx
make install

# Create symlink for easier access
ln -sf /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

echo "Nginx with nchan module built successfully!"
nginx -V
EOF

RUN chmod +x /usr/src/build-nginx.sh

# Build nginx with nchan initially
RUN /usr/src/build-nginx.sh

# Create nginx configuration directory structure
RUN mkdir -p /etc/nginx/conf.d

# Create basic nginx configuration for development
COPY <<EOF /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log debug;
pid /var/run/nginx/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Nchan shared memory
    nchan_shared_memory_size 128M;

    # Basic pub/sub endpoints for testing
    server {
        listen 80;
        server_name localhost;
        
        # Publisher endpoint
        location ~ /pub/(.*)\$ {
            nchan_publisher;
            nchan_channel_id \$1;
            nchan_message_buffer_length 50;
            nchan_message_timeout 5m;
        }
        
        # Subscriber endpoint
        location ~ /sub/(.*)\$ {
            nchan_subscriber;
            nchan_channel_id \$1;
            nchan_subscriber_first_message oldest;
        }
        
        # Combined pub/sub endpoint
        location ~ /pubsub/(.*)\$ {
            nchan_pubsub;
            nchan_channel_id \$1;
            nchan_message_buffer_length 50;
            nchan_message_timeout 5m;
        }
        
        # Channel statistics
        location ~ /stats/(.*)\$ {
            nchan_publisher;
            nchan_channel_id \$1;
        }
        
        # Nchan status page
        location /nchan_stats {
            nchan_stub_status;
        }
        
        # Static content for testing
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        # Health check
        location /health {
            return 200 "OK\\n";
            add_header Content-Type text/plain;
        }
    }
    
    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Create a simple HTML page for testing
RUN mkdir -p /usr/share/nginx/html
COPY <<EOF /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Nchan Development Environment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .endpoint { background: #f4f4f4; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .method { font-weight: bold; color: #333; }
        pre { background: #333; color: #fff; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Nchan Development Environment</h1>
        <p>Welcome to your Nchan development environment! This nginx instance is compiled with the Nchan module.</p>
        
        <h2>📋 Available Endpoints</h2>
        
        <div class="endpoint">
            <div class="method">POST /pub/{channel_id}</div>
            <div>Publish messages to a channel</div>
        </div>
        
        <div class="endpoint">
            <div class="method">GET /sub/{channel_id}</div>
            <div>Subscribe to a channel (long-polling)</div>
        </div>
        
        <div class="endpoint">
            <div class="method">GET|POST /pubsub/{channel_id}</div>
            <div>Combined publisher/subscriber endpoint</div>
        </div>
        
        <div class="endpoint">
            <div class="method">GET /stats/{channel_id}</div>
            <div>Get channel statistics</div>
        </div>
        
        <div class="endpoint">
            <div class="method">GET /nchan_stats</div>
            <div>Get Nchan status and performance metrics</div>
        </div>
        
        <h2>🧪 Quick Test</h2>
        <p>Try these commands to test the pub/sub functionality:</p>
        
        <h3>1. Publish a message:</h3>
        <pre>curl -X POST -d "Hello World!" http://localhost/pub/test</pre>
        
        <h3>2. Subscribe to messages:</h3>
        <pre>curl http://localhost/sub/test</pre>
        
        <h3>3. Check channel stats:</h3>
        <pre>curl http://localhost/stats/test</pre>
        
        <h3>4. Check Nchan status:</h3>
        <pre>curl http://localhost/nchan_stats</pre>
        
        <h2>🔧 Development</h2>
        <p>The source code is mounted at <code>/usr/src/nchan</code>. To rebuild nginx with your changes:</p>
        <pre>cd /usr/src/nchan && /usr/src/build-nginx.sh && nginx -s reload</pre>
        
        <h2>📖 Documentation</h2>
        <p>For more information about Nchan, visit <a href="https://nchan.io" target="_blank">nchan.io</a></p>
    </div>
</body>
</html>
EOF

# Create entrypoint script
COPY <<EOF /docker-entrypoint.sh
#!/bin/bash
set -e

# Function to handle shutdown gracefully
shutdown() {
    echo "Shutting down nginx..."
    nginx -s quit
    exit 0
}

# Trap SIGTERM and SIGINT
trap shutdown SIGTERM SIGINT

# Create nginx directories if they don't exist
mkdir -p /var/cache/nginx/client_temp
mkdir -p /var/cache/nginx/proxy_temp  
mkdir -p /var/cache/nginx/fastcgi_temp
mkdir -p /var/cache/nginx/uwsgi_temp
mkdir -p /var/cache/nginx/scgi_temp
mkdir -p /var/run/nginx

# Set proper permissions
chown -R nginx:nginx /var/cache/nginx
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /var/run/nginx

# If REBUILD is set, rebuild nginx with latest changes
if [ "\$REBUILD" = "true" ] || [ "\$REBUILD" = "1" ]; then
    echo "Rebuilding nginx with nchan module..."
    /usr/src/build-nginx.sh
fi

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

# Start nginx in the foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"
EOF

RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Set up volume mount points
VOLUME ["/usr/src/nchan", "/etc/nginx", "/var/log/nginx"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]