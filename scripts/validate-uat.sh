#!/usr/bin/env bash
set -euo pipefail
APP_IP=${1:-}
DB_IP=${2:-}
if [ -z "$APP_IP" ] || [ -z "$DB_IP" ]; then
  echo "Usage: validate-uat.sh <app_ip> <db_ip>"
  exit 2
fi
echo "Checking HTTP on ${APP_IP}"
curl -f --retry 5 --retry-delay 5 --max-time 10 http://${APP_IP}/health || curl -f --retry 3 http://${APP_IP}/
echo "Checking DB TCP port on ${DB_IP}:3306"
nc -z -w 5 ${DB_IP} 3306
echo "Validation completed"
