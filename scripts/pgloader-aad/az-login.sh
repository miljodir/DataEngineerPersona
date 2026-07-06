#!/usr/bin/env bash
# One-time (and re-run whenever the session expires) interactive Azure login
# for the AAD-enabled pgloader container. Stores the MSAL token cache in a
# named podman volume so subsequent pgloader runs (and DefaultAzureCredential's
# AzureCliCredential fallback) can reuse it without logging in again.
#
# Usage: wsl bash -c "scripts/pgloader-aad/az-login.sh"
set -euo pipefail
IMAGE_TAG="${PGLOADER_AAD_IMAGE:-pgloader-v4-aad:latest}"
VOLUME_NAME="${PGLOADER_AAD_VOLUME:-pgloader-aad-azure-config}"

podman volume inspect "$VOLUME_NAME" >/dev/null 2>&1 || podman volume create "$VOLUME_NAME" >/dev/null

echo "Logging in inside the pgloader-aad container (device code flow)."
echo "Open the printed URL in any browser and enter the code shown."
echo ""

podman run --rm -it --network=host \
  --userns=keep-id --user "$(id -u):$(id -g)" \
  -v "$VOLUME_NAME:/home/pgloader/.azure" \
  -e HOME=/home/pgloader \
  --entrypoint az \
  "$IMAGE_TAG" \
  login --use-device-code

echo ""
echo "Login stored in podman volume '$VOLUME_NAME'. This volume is mounted"
echo "automatically by scripts/migrate-endpoint.sh when SQLSERVER_AUTH_MODE=aad."
