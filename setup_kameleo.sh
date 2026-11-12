#!/bin/bash
exec > /workspaces/cloud-sandbox/kameleo_install.log 2>&1
echo "=== Starting Kameleo Check at $(date) ==="

KAMELEO_PAT="VGJFmujnJH-eB0zy5gpXHao-kf1ju6QWm3Je15LcyzQ"

# Check if container is running, if not run it
if ! docker ps | grep -q kameleo-app; then
  echo "Starting kameleo-app container..."
  docker rm -f kameleo-app || true
  docker run -d --name kameleo-app \
    --platform linux/amd64 \
    --shm-size=2g \
    -p 5050:5050 \
    -e PAT="$KAMELEO_PAT" \
    -v kameleo-data:/data \
    --restart unless-stopped \
    kameleo/kameleo-app:latest
fi

echo "Waiting for Kameleo /general/user-info to return 200 OK..."
SUCCESS=0
for i in $(seq 1 60); do
  RESP=$(curl -s http://127.0.0.1:5050/general/user-info || true)
  if echo "$RESP" | grep -q '"plan"'; then
    echo "KAMELEO READY! User info response:"
    echo "$RESP"
    echo "$RESP" > /workspaces/cloud-sandbox/kameleo_user_info.json
    SUCCESS=1
    break
  fi
  echo "Attempt $i: waiting (got: ${RESP:0:80})..."
  sleep 2
done

echo "=== Docker Status ==="
docker ps -a
docker logs --tail 40 kameleo-app

echo "=== Completed at $(date) with SUCCESS=$SUCCESS ==="

cd /workspaces/cloud-sandbox
git config --global user.name "SandboxBot"
git config --global user.email "bot@sandbox.dev"
git add kameleo_install.log kameleo_user_info.json || true
git commit -m "Update: Kameleo trial user info [auto]" || true
git push origin main || true
