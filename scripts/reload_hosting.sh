#!/bin/bash

function rode_echo() { echo -e "\e[31m$1\e[0m"; }
function groene_echo() { echo -e "\e[32m$1\e[0m"; }

groene_echo "Reloading hosting services..."
systemctl restart cloudflared || rode_echo "Failed to restart cloudflared"
groene_echo "Hosting services reloaded successfully"
