#!/bin/nash 

# intrusion_detection_simulator.sh: 
# simulation of intrusion detection when using SSH login attempt and fails 

LOG_FILE="/var/log/auth.log"
echo "~* Check for potential brute-force SSH login attempts *~"

# Checks for Failed Password 
grep "Failed password" $LOG_FILE | awk '{print $11}' | sort | uniq -c | sort -nr | head
