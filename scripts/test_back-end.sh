#!/bin/bash

BACKEND_SERVERS=("192.168.30.120" "192.168.30.125" "192.168.30.130")
PORT=5000

for server in "${BACKEND_SERVERS[@]}"; do
  echo "Testing backend server $server on port $PORT..."
  if curl -s --head "http://$server:$PORT" | grep "200 OK" > /dev/null; then
    echo "Server $server is responding on port $PORT"
  else
    echo "Server $server is NOT responding on port $PORT"
    exit 1
  fi
done

echo "All backend servers are responding on port $PORT"
