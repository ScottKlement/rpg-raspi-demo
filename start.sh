#!/bin/bash
cd `dirname $0`
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Reset GPIO pins
gpio mode 4 output
gpio mode 5 output
gpio mode 6 output
gpio mode 13 output
gpio mode 19 output
gpio mode 26 output
gpio mode 23 up

# wait 15 seconds if root, then start server
if [ `id -u` -eq 0 ]; then
   sleep 15
fi
node start
