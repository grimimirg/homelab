#!/bin/bash

echo "Testing Docker Stats API..."
echo ""

# Go to project root to find .env
cd "$(dirname "$0")/.."

if [ -f ".env" ]; then
    source .env
else
    echo "ERROR: .env not found in project root!"
    exit 1
fi

echo "1. Testing health endpoint..."
curl -s "https://${DOMAIN}/health" | jq .
echo ""

echo "2. Testing stats endpoint (requires authentication)..."
echo "   URL: https://${DOMAIN}/api/docker/stats"
echo ""
echo "   You need to be authenticated via Authelia to access this endpoint."
echo "   Open your browser and visit: https://${DOMAIN}/api/docker/stats"
echo ""

echo "3. Testing local API (if running locally on port 5000)..."
if curl -s http://localhost:5000/api/docker/stats > /dev/null 2>&1; then
    echo "   Local API is responding:"
    curl -s http://localhost:5000/api/docker/stats | jq .
else
    echo "   Local API is not accessible (container might not be running)"
fi
