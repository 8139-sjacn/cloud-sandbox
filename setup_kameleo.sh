#!/bin/bash
exec > /workspaces/cloud-sandbox/kameleo_setup.log 2>&1
echo "=== Starting Kameleo Isolated Setup at $(date) ==="
echo "CODESPACE_NAME=$CODESPACE_NAME"

if [[ "$CODESPACE_NAME" == *"sandbox-1"* ]]; then
  KAMELEO_PAT="VGJFmujnJH-eB0zy5gpXHao-kf1ju6QWm3Je15LcyzQ"
  ACCOUNT_LABEL="Account-1-StevenBrown"
else
  KAMELEO_PAT="ptbOxqfWDA-5HR1_OP60TesfkM6f--q9L15wb-N9k8E"
  ACCOUNT_LABEL="Account-2-NathanCortez"
fi

echo "Assigned Account: $ACCOUNT_LABEL"

docker rm -f kameleo-app || true
docker run -d --name kameleo-app \
  --platform linux/amd64 \
  --shm-size=2g \
  -p 5050:5050 \
  -e PAT="$KAMELEO_PAT" \
  -v kameleo-data:/data \
  --restart unless-stopped \
  kameleo/kameleo-app:latest

echo "Waiting for port 5050 to become ready..."
for i in $(seq 1 80); do
  RESP=$(curl -s http://127.0.0.1:5050/general/user-info || echo fail)
  if echo "$RESP" | grep -q '"plan"'; then
    echo "Kameleo API 200 OK!"
    echo "$RESP" > /workspaces/cloud-sandbox/kameleo_report_${CODESPACE_NAME}.json
    break
  fi
  echo "wait $i $RESP"
  sleep 5
done

cd /workspaces/cloud-sandbox
git config --global user.name "SandboxBot"
git config --global user.email "bot@sandbox.dev"
git pull --rebase origin main || true
git add kameleo_report_${CODESPACE_NAME}.json kameleo_setup.log || true
git commit -m "Report: Isolated Kameleo trial for ${CODESPACE_NAME}" || true
git push origin main || true
