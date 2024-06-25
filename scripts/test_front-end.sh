#!/bin/bash

FRONTEND_SERVERS=("192.168.30.105" "192.168.30.110" "192.168.30.115")
PORTS=(8080 8079)

for server in "${FRONTEND_SERVERS[@]}"; do
  for port in "${PORTS[@]}"; do
    echo "Testing frontend server $server on port $port..."
    if curl -s --head "http://$server:$port" | grep "200 OK" > /dev/null; then
      echo "Server $server is responding on port $port"
    else
      echo "Server $server is NOT responding on port $port"
      exit 1
    fi
  done
done

echo "All frontend servers are responding on ports ${PORTS[@]}"
