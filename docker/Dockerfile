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

# Copy and set up build script
COPY docker/build-nginx.sh /usr/src/build-nginx.sh
RUN chmod +x /usr/src/build-nginx.sh

# Build nginx with nchan initially
RUN /usr/src/build-nginx.sh

# Create nginx configuration directory structure
RUN mkdir -p /etc/nginx/conf.d

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Create a simple HTML page for testing
RUN mkdir -p /usr/share/nginx/html
COPY docker/index.html /usr/share/nginx/html/index.html

# Copy and set up entrypoint script
COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

# Set up volume mount points
VOLUME ["/usr/src/nchan", "/etc/nginx", "/var/log/nginx"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]