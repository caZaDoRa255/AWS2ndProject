#!/bin/bash

echo "[1/6] git add ."
git add .

echo "[2/6] Registering git-secrets AWS patterns..."
git secrets --register-aws > /dev/null 2>&1

echo "[3/6] Running git-secrets scan..."
if git secrets --scan > /tmp/git_secrets_log.txt 2>&1; then
  echo "[OK] No secrets detected."
else
  echo "[ERROR] Secrets detected! Commit aborted."
  echo "---- Detected Output ----"
  cat /tmp/git_secrets_log.txt
  echo "--------------------------"
  exit 1
fi

echo "[4/6] Enter your commit message:"
read -p "Commit message: " msg

echo "[5/6] Committing..."
git commit -m "$msg"

echo "[6/6] Pushing to origin main..."
git push origin main