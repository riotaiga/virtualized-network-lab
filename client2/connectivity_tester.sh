#!/bin/bash
# This script tests connectivity to the server and router.

echo "[+] Pinging Server (192.168.56.10)..."
ping -c 3 192.168.56.10

echo "[+] Pinging Router (192.168.56.1)..."
ping -c 3 192.168.56.1