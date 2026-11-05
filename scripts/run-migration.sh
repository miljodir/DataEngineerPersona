#!/usr/bin/env bash
# Execute the migration
# Usage: ./scripts/run-migration.sh [--config <path>] [--dry-run]
# Bash equivalent of scripts/run-migration.ps1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/pgloader-local.sh"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.env"
    set +a
fi

PGLOADER_RUNTIME="${PGLOADER_RUNTIME:-podman}"
PGLOADER_IMAGE="${PGLOADER_IMAGE:-ghcr.io/dimitri/pgloader-v4:latest}"

# Defaults
PGLOADER_CONFIG="samples/wide-world-importers/migration-scripts/pgloader.load"
DRY_RUN=true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config) PGLOADER_CONFIG="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --execute) DRY_RUN=false; shift ;;
        -h|--help)
            echo "Usage: $0 [--config <path>] [--dry-run|--execute]"
            echo "  --dry-run   Validate only (default)"
            echo "  --execute   Run actual data migration"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "=== Phase 2: Migration Execution ==="
echo "pgLoader config: $PGLOADER_CONFIG"
echo ""

pgloader() {
    local config_path="$PGLOADER_CONFIG"
    if [[ "$config_path" != /* ]]; then
        config_path="$REPO_ROOT/$config_path"
    fi
    if [[ ! -f "$config_path" ]]; then
        echo "pgLoader config not found: $config_path" >&2
        return 1
    fi
    if [[ "$PGLOADER_RUNTIME" == "local" ]]; then
        pgloader_local_run "$@" "$config_path"
        return
    fi

    if [[ "$PGLOADER_RUNTIME" != "podman" ]]; then
        echo "PGLOADER_RUNTIME must be 'podman' or 'local' (got '$PGLOADER_RUNTIME')." >&2
        return 1
    fi
    if ! command -v podman &>/dev/null; then
        echo "Podman not found. It is required for the default PGLOADER_RUNTIME=podman." >&2
        return 127
    fi

    local config_dir
    config_dir="$(cd "$(dirname "$config_path")" && pwd)"
    local config_name
    config_name="$(basename "$config_path")"
    podman run --rm --network=host \
        --volume "$config_dir:$config_dir:ro" \
        --workdir "$config_dir" \
        "$PGLOADER_IMAGE" "$@" "$config_name"
}

echo "[1/3] Running pgLoader dry-run (validation only)..."
pgloader --dry-run 2>&1
echo "  Dry-run complete. Review output for type mapping issues."

if [ "$DRY_RUN" = false ]; then
    echo ""
    read -rp "Proceed with actual data migration? (y/N) " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "[2/3] Running pgLoader data transfer..."
        pgloader 2>&1
        echo "  Data transfer complete."
    else
        echo "  Migration aborted by user."
        exit 0
    fi
fi

# Step 2: sqlfluff lint
if command -v sqlfluff &>/dev/null; then
    echo "[3/3] Linting PL/pgSQL with sqlfluff..."
    sqlfluff lint samples/wide-world-importers/migration-scripts/tsql-to-plpgsql/ --dialect postgres 2>&1
else
    echo "[3/3] sqlfluff not found - skipping (install: pip install sqlfluff)"
fi

echo ""
echo "Migration execution complete. Run ./scripts/validate-migration.sh for Phase 3."
