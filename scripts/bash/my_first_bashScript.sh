#!/bin/bash
# My first Bash script displays basic system information.

echo "Hello, $(whoami)"
echo "Host: $(hostname)"
sleep 3
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"

Variable="my name is Pandey"

echo "Full string: ${Variable:0}"
echo "Substring: ${Variable:2:5}"
echo "Remove prefix: ${Variable#my }"
echo "Remove suffix: ${Variable% Pandey}"
echo "Uppercase: ${Variable^^}"
echo "Lowercase: ${Variable,,}"

echo "Script: $0"
echo "First arg: $1"
echo "Argument count: $#"
echo "ALL args: $@"
