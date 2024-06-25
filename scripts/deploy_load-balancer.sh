#!/bin/bash

function rode_echo() { echo -e "\e[31m$1\e[0m"; }
function groene_echo() { echo -e "\e[32m$1\e[0m"; }

groene_echo "Deploying load balancer..."

groene_echo "Updating and installing required packages..."
apt update && apt install -y nginx nginx-extras || rode_echo "Failed to install packages"

groene_echo "Copying nginx.conf to load balancer..."
cp /root/24/Loadbalancer/nginx.conf /etc/nginx/nginx.conf || rode_echo "Failed to copy nginx.conf to load balancer"

groene_echo "Restarting nginx service..."
systemctl restart nginx || rode_echo "Failed to restart nginx"
