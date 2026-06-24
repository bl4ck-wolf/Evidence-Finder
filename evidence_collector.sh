#!/bin/bash

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DIR="evidence_$TIMESTAMP"
mkdir -p "$DIR"

REPORT="$DIR/intrusion_report.txt"
HASHFILE="$DIR/file_hashes.txt"
CHAIN="$DIR/chain_of_custody.txt"

##############################################
# REPORT HEADER
##############################################
echo "=== INTRUSION EVIDENCE REPORT (KALI) ===" > "$REPORT"
echo "Generated: $(date)" >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# SYSTEM INFORMATION
##############################################
echo "=== SYSTEM INFO ===" >> "$REPORT"
uname -a >> "$REPORT"
hostnamectl >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# SSH LOGS VIA JOURNALCTL
##############################################
echo "=== SSH LOGS (journalctl) ===" >> "$REPORT"
sudo journalctl -u ssh >> "$REPORT" 2>/dev/null
sudo journalctl -u sshd >> "$REPORT" 2>/dev/null
echo "" >> "$REPORT"

##############################################
# LOGIN ATTEMPTS
##############################################
echo "=== LOGIN ATTEMPTS (Accepted / Failed) ===" >> "$REPORT"
sudo journalctl | grep -Ei 'Accepted|Failed|Invalid' >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# EXTRACT IP ADDRESSES
##############################################
echo "=== EXTRACTED IP ADDRESSES ===" >> "$REPORT"
IPS=$(sudo journalctl | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
echo "$IPS" >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# WHOIS LOOKUP FOR IPs
##############################################
echo "=== WHOIS LOOKUP ===" >> "$REPORT"
for ip in $IPS; do
    echo "--- WHOIS for $ip ---" >> "$REPORT"
    whois "$ip" >> "$REPORT" 2>/dev/null
    echo "" >> "$REPORT"
done

##############################################
# SESSION HISTORY
##############################################
echo "=== Active Sessions ===" >> "$REPORT"
who >> "$REPORT"
w >> "$REPORT"
echo "" >> "$REPORT"

echo "=== Login History ===" >> "$REPORT"
last >> "$REPORT"
echo "" >> "$REPORT"

echo "=== Failed Logins (lastb) ===" >> "$REPORT"
lastb >> "$REPORT" 2>/dev/null
echo "" >> "$REPORT"

##############################################
# NETWORK + PROCESSES
##############################################
echo "=== Network Connections ===" >> "$REPORT"
sudo ss -tuna >> "$REPORT"
echo "" >> "$REPORT"

echo "=== Running Processes ===" >> "$REPORT"
ps aux >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# RECENTLY MODIFIED FILES
##############################################
echo "=== Modified Files (48h) ===" >> "$REPORT"
sudo find / -mtime -2 -type f 2>/dev/null >> "$REPORT"
echo "" >> "$REPORT"

##############################################
# HASHING
##############################################
echo "=== FILE HASHES (SHA-256) ===" > "$HASHFILE"
sha256sum "$REPORT" >> "$HASHFILE"
date >> "$HASHFILE"

##############################################
# CHAIN OF CUSTODY
##############################################
echo "=== CHAIN OF CUSTODY ===" > "$CHAIN"
echo "Evidence Directory: $DIR" >> "$CHAIN"
echo "Collected By (Your Name): ___________________" >> "$CHAIN"
echo "Time: $(date)" >> "$CHAIN"
echo "Report Hash: $(sha256sum "$REPORT")" >> "$CHAIN"

##############################################
# PACKAGE EVERYTHING
##############################################
tar -czf "$DIR.tar.gz" "$DIR"

echo ""
echo "Evidence package ready: $DIR.tar.gz"
