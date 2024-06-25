#!/bin/bash

set -x  # Enable debug mode

function rode_echo() { echo -e "\e[31m$1\e[0m"; }
function groene_echo() { echo -e "\e[32m$1\e[0m"; }

groene_echo "Starting backend deployment script..."

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

groene_echo "Navigating to backend directory..."
cd "/root/24/Backend"

groene_echo "Installing backend packages..."
poetry install

groene_echo "Starting backend app on port 5000..."
poetry run gunicorn app:app --bind 0.0.0.0:5000 --daemon
