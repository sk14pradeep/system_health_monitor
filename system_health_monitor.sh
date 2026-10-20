#!/bin/bash
# ---------------------------------------------------------
# System Health Monitor
# Usage:  ./health_monitor.sh            (run once)
#         ./health_monitor.sh -w 5       (repeat every 5 seconds)
# ---------------------------------------------------------

# ---- Thresholds (percent) ----
CPU_LIMIT=80
MEM_LIMIT=80
DISK_LIMIT=80

LOG_FILE="$HOME/health_monitor.log"

# ---- Colors ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# ---- Get CPU usage (%) by sampling /proc/stat twice ----
get_cpu() {
    read -r _ u1 n1 s1 i1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 _ < /proc/stat
    local busy=$(( (u2+n2+s2) - (u1+n1+s1) ))
    local total=$(( busy + (i2 - i1) ))
    echo $(( 100 * busy / total ))
}

# ---- Get memory usage (%) ----
get_mem() {
    free | awk '/^Mem:/ {printf "%d", $3*100/$2}'
}

# ---- Get disk usage (%) of root partition ----
get_disk() {
    df / | awk 'NR==2 {gsub("%",""); print $5}'
}

# ---- Print one line with OK/WARNING status ----
check() {
    local name=$1 value=$2 limit=$3
    if [ "$value" -ge "$limit" ]; then
        echo -e "$name: ${RED}${value}% [WARNING]${NC}"
        echo "$(date '+%F %T') WARNING: $name at ${value}% (limit ${limit}%)" >> "$LOG_FILE"
    else
        echo -e "$name: ${GREEN}${value}% [OK]${NC}"
    fi
}

report() {
    echo "=========================================="
    echo " System Health Report - $(date '+%F %T')"
    echo "=========================================="
    echo "Hostname : $(hostname)"
    echo "Uptime   : $(uptime -p)"
    echo "Load avg : $(awk '{print $1, $2, $3}' /proc/loadavg)"
    echo "------------------------------------------"

    check "CPU   " "$(get_cpu)"  "$CPU_LIMIT"
    check "Memory" "$(get_mem)"  "$MEM_LIMIT"
    check "Disk  " "$(get_disk)" "$DISK_LIMIT"

    echo "------------------------------------------"
    echo "Top 5 processes by CPU:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
    echo
}

# ---- Main ----
if [ "$1" == "-w" ]; then
    interval=${2:-5}
    while true; do
        clear
        report
        sleep "$interval"
    done
else
    report
fi
