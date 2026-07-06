#!/usr/bin/env bash
# Builds the AAD-enabled pgloader-v4 image (see Dockerfile for why).
# Usage: wsl bash -c "cd scripts/pgloader-aad && ./build.sh"
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_TAG="${PGLOADER_AAD_IMAGE:-pgloader-v4-aad:latest}"

echo "Building $IMAGE_TAG from $SCRIPT_DIR ..."
podman build -t "$IMAGE_TAG" "$SCRIPT_DIR"
echo ""
echo "Done. Run scripts/pgloader-aad/az-login.sh once to authenticate, then set"
echo "SQLSERVER_AUTH_MODE=aad in .env before running scripts/migrate-endpoint.sh."
