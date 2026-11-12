#!/bin/bash
set -e
exec > /workspaces/cloud-sandbox/kameleo_install.log 2>&1
echo "=== Starting Kameleo Installation at $(date) ==="
uname -a
docker --version

KAMELEO_PAT="VGJFmujnJH-eB0zy5gpXHao-kf1ju6QWm3Je15LcyzQ"

echo "Pulling kameleo/kameleo-app:latest ..."
docker pull kameleo/kameleo-app:latest

echo "Running kameleo-app container ..."
docker run -d --name kameleo-app   --platform linux/amd64   --shm-size=2g   -p 5050:5050   -e PAT="$KAMELEO_PAT"   -v kameleo-data:/data   --restart unless-stopped   kameleo/kameleo-app:latest

echo "Waiting for Kameleo port 5050 to respond ..."
for i in $(seq 1 40); do
  if curl -s http://127.0.0.1:5050/general/user-info > /workspaces/cloud-sandbox/kameleo_user_info.json; then
    echo "Kameleo started successfully!"
    break
  fi
  sleep 2
done

echo "=== Docker status & logs ==="
docker ps -a
docker logs kameleo-app

echo "=== Completed at $(date) ==="

git config --global user.name "SandboxBot"
git config --global user.email "bot@sandbox.dev"
git add /workspaces/cloud-sandbox/kameleo_install.log /workspaces/cloud-sandbox/kameleo_user_info.json || true
git commit -m "Auto report: Kameleo installation and trial info" || true
git push origin main || true
