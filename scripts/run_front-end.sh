#!/bin/bash

function rode_echo() { echo -e "\e[31m$1\e[0m"; }
function groene_echo() { echo -e "\e[32m$1\e[0m"; }

groene_echo "Starting frontend deployment script..."

groene_echo "Updating package lists..."
sudo apt update

groene_echo "Installing poetry module..."
sudo apt install -y python3-poetry

groene_echo "Killing existing poetry and gunicorn processes..."
pkill -f poetry
pkill -f gunicorn

groene_echo "Stopping and removing all virtual environments..."
find . -type d -name "venv" | while read venv_path; do
    echo "Venv found: $venv_path"
    pids=$(ps aux | grep "${venv_path}/bin/python" | grep -v grep | awk '{print $2}')
    if [ -n "$pids" ]; then
        echo "Killing process: $pids"
        kill -9 $pids
    fi
    echo "Removing venv directory: $venv_path"
    rm -rf "$venv_path"
done
echo "All venvs are stopped and removed."

groene_echo "Navigating to frontend directory..."
cd "/root/24/Frontend"

groene_echo "Clearing static/cache directory..."
CACHE_DIR="/root/24/Frontend/static/cache"
if [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR/*"
else
  mkdir -p "$CACHE_DIR"
fi

groene_echo "Installing frontend packages..."
poetry install

BACKENDS=("http://192.168.30.120:5000" "http://192.168.30.125:5000" "http://192.168.30.130:5000")
export SAXCOIN_BACKEND=$(IFS=,; echo "${BACKENDS[*]}")

WORKERS=2
THREADS=4

groene_echo "Starting .online app on port 8080..."
poetry run gunicorn app:app --bind 0.0.0.0:8080 --workers $WORKERS --threads $THREADS --timeout 120 --daemon

groene_echo "Starting .nl app on port 8079..."
poetry run gunicorn app_landing:app --bind 0.0.0.0:8079 --workers $WORKERS --threads $THREADS --timeout 120 --daemon
