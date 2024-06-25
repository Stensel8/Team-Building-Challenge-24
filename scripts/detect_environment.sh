#!/bin/bash

# Define backend and frontend servers
BACKEND_SERVERS=("192.168.30.120" "192.168.30.125" "192.168.30.130")
FRONTEND_SERVERS=("192.168.30.105" "192.168.30.110" "192.168.30.115")

echo -e "\e[34mDetecting environment...\e[0m"
RUNNING_BACKEND_SERVERS=""
RUNNING_FRONTEND_SERVERS=""

for server in "${BACKEND_SERVERS[@]}"; do
  if ping -c 1 "$server" &> /dev/null; then
    echo -e "\e[32m$server: Responding\e[0m"
    RUNNING_BACKEND_SERVERS="$RUNNING_BACKEND_SERVERS $server"
  else
    echo -e "\e[31m$server: Not responding\e[0m"
  fi
done

for server in "${FRONTEND_SERVERS[@]}"; do
  if ping -c 1 "$server" &> /dev/null; then
    echo -e "\e[32m$server: Responding\e[0m"
    RUNNING_FRONTEND_SERVERS="$RUNNING_FRONTEND_SERVERS $server"
  else
    echo -e "\e[31m$server: Not responding\e[0m"
  fi
done

if [ -z "$RUNNING_BACKEND_SERVERS" ]; then
  echo -e "\e[31mNo backend servers are running. Exiting...\e[0m"
  exit 1
fi

if [ -z "$RUNNING_FRONTEND_SERVERS" ]; then
  echo -e "\e[31mNo frontend servers are running. Exiting...\e[0m"
  exit 1
fi

echo -e "\e[34mRunning backend servers: $RUNNING_BACKEND_SERVERS\e[0m"
echo -e "\e[34mRunning frontend servers: $RUNNING_FRONTEND_SERVERS\e[0m"

# Save running servers to files
echo "$RUNNING_BACKEND_SERVERS" > backend_servers.txt
echo "$RUNNING_FRONTEND_SERVERS" > frontend_servers.txt

