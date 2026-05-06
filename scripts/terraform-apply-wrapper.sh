#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <working_dir> <planfile>"
  echo "Example: $0 env/uat env/uat/tfplan"
  exit 2
fi

DIR="$1"
PLANFILE="$2"

MAX_RETRIES=6
SLEEP_BASE=10

for i in $(seq 1 $MAX_RETRIES); do
  echo "terraform apply attempt $i"
  OUTPUT=$(terraform -chdir="$DIR" apply -auto-approve "$PLANFILE" 2>&1) || STATUS=$?
  if [ "${STATUS:-0}" = "0" ]; then
    echo "$OUTPUT"
    echo "apply succeeded"
    exit 0
  fi
  echo "$OUTPUT"
  if echo "$OUTPUT" | grep -q "Error acquiring the state lock"; then
    WAIT=$((SLEEP_BASE * i))
    echo "state lock detected — retrying in ${WAIT}s"
    sleep ${WAIT}
    continue
  fi
  exit ${STATUS:-1}
done
exit 1
