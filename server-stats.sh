#!/bin/bash

#
# server-stats.sh
#
# Description:
#   A simple script to display key server performance statistics,
#   including CPU, memory, disk usage, and top processes.
#
# Author:
#   Eduxcode
#

# --- Style and Formatting ---
SEPARATOR="=========================================================="

# --- Main Logic ---

echo ""
echo "           Server Performance Statistics Report"
echo "$SEPARATOR"
echo "Report generated on: $(date)"
echo "$SEPARATOR"


## ℹ️ System Information
echo ""
echo "## ℹ️ System Information"
# OS Information from /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    os_name="$PRETTY_NAME"
else
    os_name="$(uname -s) $(uname -r)"
fi

# Get other system details
current_uptime=$(uptime -p | sed 's/up //')
load_average=$(uptime | awk -F'load average: ' '{print $2}')
user_count=$(who | wc -l)
user_list=$(who | awk '{print $1}' | sort -u | tr '\n' ', ' | sed 's/, $//')

# Print formatted system info
printf "%-16s: %s\n" "OS Version" "$os_name"
printf "%-16s: %s\n" "Uptime" "$current_uptime"
printf "%-16s: %s\n" "Load Average" "$load_average"
printf "%-16s: %d (%s)\n" "Logged-in Users" "$user_count" "$user_list"



## 📊 Total CPU Usage
# We get the CPU idle percentage from `top` and subtract it from 100
# to find the total usage. `LC_NUMERIC=C` ensures consistent decimal point formatting.
cpu_usage=$(LC_NUMERIC=C top -b -n1 | grep "Cpu(s)" | awk '{printf "%.2f", 100 - $8}')
echo ""
echo "## 📊 Total CPU Usage"
echo "CPU Usage: ${cpu_usage}%"


## 🧠 Total Memory Usage
# We use `free -m` to get memory details in megabytes and format the output.
echo ""
echo "## 🧠 Total Memory Usage"
free -m | grep Mem | awk '{
    total=$2;
    used=$3;
    free=$4;
    percentage=(used/total)*100;
    printf "Total:    %s MB\n", total;
    printf "Used:     %s MB (%.2f%%)\n", used, percentage;
    printf "Free:     %s MB\n", free;
}'


## 💾 Total Disk Usage
# We use `df -h --total` which provides a summary line for all filesystems.
# The `tail -n 1` command isolates this total summary line for processing.
echo ""
echo "## 💾 Total Disk Usage (Overall)"
df -h --total | tail -n 1 | awk '{
    total=$2;
    used=$3;
    free=$4;
    percentage=$5;
    printf "Total:    %s\n", total;
    printf "Used:     %s (%s)\n", used, percentage;
    printf "Free:     %s\n", free;
}'


## 🚀 Top 5 Processes by CPU Usage
# `ps aux` lists all running processes. We then sort them by the %CPU
# column in descending order and take the top 5 results using `head`.
echo ""
echo "## 🚀 Top 5 Processes by CPU Usage"
ps aux --sort=-%cpu | head -n 6


## 📈 Top 5 Processes by Memory Usage
# This is similar to the CPU check, but we sort by the %MEM column instead.
echo ""
echo "## 📈 Top 5 Processes by Memory Usage"
ps aux --sort=-%mem | head -n 6

# 🔒 Security Information
echo ""
echo "## 🔒 Security Information"
# Count failed login attempts using the `lastb` command.
# Note: `lastb` may require root privileges to read /var/log/btmp.
if command -v lastb &> /dev/null; then
    # The command `lastb` returns non-zero if the log file doesn't exist.
    # We redirect stderr to /dev/null to suppress "no such file" errors.
    failed_logins=$(lastb 2>/dev/null | wc -l)
    printf "%-25s: %s\n" "Failed login attempts" "$failed_logins (since log file start)"
else
    printf "%-25s: %s\n" "Failed login attempts" "'lastb' command not found."
fi

echo ""
echo "$SEPARATOR"
echo ""
