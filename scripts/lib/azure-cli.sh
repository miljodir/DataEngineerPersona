#!/usr/bin/env bash

# Verifies the Azure CLI login used by pgloader's ActiveDirectoryDefault
# (AzureCliCredential). Run `az login` in the same shell/WSL distro first.
configure_azure_cli() {
    if ! command -v az >/dev/null 2>&1; then
        echo "ERROR: Azure CLI (az) is required for SQLSERVER_AUTH_MODE=aad." >&2
        return 127
    fi
    if ! az account show --output none </dev/null >/dev/null 2>&1; then
        echo "ERROR: Azure CLI is not signed in. Run: az login" >&2
        return 1
    fi
}