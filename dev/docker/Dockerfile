# Nchan Development Environment - Debian
# Supports Ruby, Lua, C, and Bash development with all necessary dependencies
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WORKDIR=/app
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV LANGUAGE=C.UTF-8

# Install system dependencies (comprehensive set from prepare.sh + additional dev tools)
RUN apt-get update && apt-get install -y \
    # Essential build tools
    build-essential \
    gcc \
    make \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    curl \
    wget \
    zsh \
    # Nginx build dependencies (from prepare.sh)
    libssl-dev \
    libpcre3-dev \
    zlib1g-dev \
    # Ruby dependencies (from prepare.sh)
    ruby \
    ruby-dev \
    bundler \
    libxslt-dev \
    libxml2-dev \
    libyaml-dev \
    # Lua development
    lua5.2 \
    lua5.2-dev \
    luarocks \
    # Python and related tools
    python3 \
    python3-pip \
    python3-dev \
    # System utilities and development tools (from prepare.sh)
    vim \
    emacs \
    htop \
    lsof \
    strace \
    gdb \
    valgrind \
    procps \
    psmisc \
    net-tools \
    netcat-openbsd \
    telnet \
    # Network and testing tools
    redis-tools \
    # Additional development utilities
    jq \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install wrk for HTTP benchmarking
RUN cd /tmp && \
    git clone https://github.com/wg/wrk.git && \
    cd wrk && \
    make && \
    cp wrk /usr/local/bin/ && \
    cd / && rm -rf /tmp/wrk

# Install Artillery for advanced load testing
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g artillery@latest && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR $WORKDIR

# Create user for development (matches host user permissions)
RUN groupadd -g 1000 developer && \
    useradd -u 1000 -g developer -m -s /bin/bash developer && \
    chown -R developer:developer $WORKDIR

# Configure git globally for safe directories to fix dubious ownership errors
RUN git config --global --add safe.directory '*' && \
    git config --global user.name "Developer" && \
    git config --global user.email "developer@nchan.dev"

# Switch to development user early to avoid permission issues
USER developer

# Copy necessary files for bundle install (including nchan_tools-gem) as user
COPY --chown=developer:developer dev/Gemfile* ./
COPY --chown=developer:developer dev/nchan_tools-gem ./nchan_tools-gem/

# Configure bundler for user-local gem installation before install
RUN bundle config set --local path ~/.local/gems && \
    bundle config set --local bin ~/.local/bin && \
    mkdir -p ~/.local/gems ~/.local/bin

# Install Ruby gems as user to avoid permission conflicts
RUN bundle install

# Set up shell environment with local gems in PATH
RUN echo 'export PS1="\[\033[01;32m\]nchan-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias grep="grep --color=auto"' >> ~/.bashrc && \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Health check to ensure all tools are available
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ruby --version && lua5.2 -v && gcc --version && python3 --version

# Default command
CMD ["/bin/bash"]