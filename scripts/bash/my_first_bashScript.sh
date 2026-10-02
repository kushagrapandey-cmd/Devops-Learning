#! /bin/bash
# my first bash script displays basic system informations

echo "Hello, $(whoami)"
echo "Host: $(hostname)"
sleep 3
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
