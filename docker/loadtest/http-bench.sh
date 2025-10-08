#!/bin/bash

NCHAN_HOST=${NCHAN_HOST:-nchan:80}
CHANNEL=${CHANNEL:-test}
DURATION=${DURATION:-30}
CONNECTIONS=${CONNECTIONS:-100}
RATE=${RATE:-1000}

echo "Benchmarking Nchan HTTP endpoints..."
echo "Host: $NCHAN_HOST"
echo "Channel: $CHANNEL"
echo "Duration: ${DURATION}s"
echo "Connections: $CONNECTIONS"
echo "Rate: $RATE req/s"

# Publish test
echo "Testing publisher endpoint..."
wrk -t12 -c$CONNECTIONS -d${DURATION}s -s /scripts/publish.lua http://$NCHAN_HOST/pub/$CHANNEL

# Subscribe test  
echo "Testing subscriber endpoint..."
wrk -t12 -c$CONNECTIONS -d${DURATION}s http://$NCHAN_HOST/sub/$CHANNEL