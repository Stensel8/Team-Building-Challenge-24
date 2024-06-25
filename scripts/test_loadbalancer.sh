#!/bin/bash

echo -e "\e[34mTesting load balancer configuration...\e[0m"
nginx -t || echo -e "\e[31mNginx configuration test failed\e[0m"
