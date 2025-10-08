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
if [ "$REBUILD" = "true" ] || [ "$REBUILD" = "1" ]; then
    echo "Rebuilding nginx with nchan module..."
    /usr/src/build-nginx.sh
fi

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

# Start nginx in the foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"