#!/usr/bin/env bash
# =============================================================================
# Generic SQL Server → PostgreSQL Migration (Bring Your Own Endpoint)
#
# Use this script when migrating ANY customer SQL Server to ANY PostgreSQL.
# Uses pgloader for the bulk transfer.
#
# For the WideWorldImporters local demo (podman), use migrate-data.sh instead.
#
# Connection strings come from .env. Required:
#   SQLSERVER_HOST, SQLSERVER_PORT, SQLSERVER_DB, SQLSERVER_USER, SQLSERVER_PASSWORD
#   PG_HOST,        PG_PORT,        PG_DB,        PG_USER,        PG_PASSWORD
#
# Usage:
#   wsl zsh -c "scripts/migrate-endpoint.sh"                     # full migration
#   wsl zsh -c "scripts/migrate-endpoint.sh --dry-run"           # validate only
#   wsl zsh -c "scripts/migrate-endpoint.sh --schema-only"       # tables/views only
#   wsl zsh -c "scripts/migrate-endpoint.sh --data-only"         # data only into existing target schema
#   wsl zsh -c "scripts/migrate-endpoint.sh --with-foreign-keys" # opt in to pgloader FK DDL
#   wsl zsh -c "scripts/migrate-endpoint.sh --uniquify-index-names" # add pgloader idx_<oid>_ prefix
# =============================================================================

set -euo pipefail

export SSL_CERT_FILE=/mnt/c/appl/repos/DataEngineerPersona/server-ca.pem
export TDS_MAX_CONN=100

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------------
# Load .env
# ------------------------------------------------------------------
if [ -f "$REPO_ROOT/.env" ]; then
    set -a; source "$REPO_ROOT/.env"; set +a
elif [ -f "$REPO_ROOT/.env.example" ]; then
    echo "  No .env found — using defaults from .env.example"
    set -a; source "$REPO_ROOT/.env.example"; set +a
else
    echo "ERROR: No .env or .env.example found. Copy .env.example to .env and edit." >&2
    exit 1
fi

# ------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------
DRY_RUN=false
SCHEMA_ONLY=false
DATA_ONLY=true
CREATE_FOREIGN_KEYS=false
# PGLOADER will always uniqify index names for PKs but seem to respect this for FKs
# Ref https://github.com/dimitri/pgloader/issues/1257
UNIQUIFY_INDEX_NAMES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)     DRY_RUN=true; shift ;;
        --schema-only) SCHEMA_ONLY=true; shift ;;
        --data-only)   DATA_ONLY=true; shift ;;
        --with-foreign-keys) CREATE_FOREIGN_KEYS=true; shift ;;
        --uniquify-index-names) UNIQUIFY_INDEX_NAMES=true; shift ;;
        -h|--help)
            sed -n '1,20p' "$0"
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [ "$SCHEMA_ONLY" = true ] && [ "$DATA_ONLY" = true ]; then
  echo "ERROR: --schema-only and --data-only are mutually exclusive." >&2
  exit 1
fi

# ------------------------------------------------------------------
# Resolve connection variables
# ------------------------------------------------------------------
: "${SQLSERVER_HOST:?SQLSERVER_HOST is required (set in .env)}"
: "${SQLSERVER_PORT:=1433}"
: "${SQLSERVER_DB:?SQLSERVER_DB is required (set in .env)}"
: "${SQLSERVER_USER:=sa}"
: "${SQLSERVER_PASSWORD:?SQLSERVER_PASSWORD is required (set in .env)}"

: "${PG_HOST:?PG_HOST is required (set in .env)}"
: "${PG_PORT:=5432}"
: "${PG_DB:?PG_DB is required (set in .env)}"
: "${PG_USER:?PG_USER is required (set in .env)}"
: "${PG_PASSWORD:?PG_PASSWORD is required (set in .env)}"

# Map the common .env names (set by .env.example for the demo) to BYO names
# This lets demo defaults like SA_PASSWORD work when SQLSERVER_PASSWORD is unset.
SQLSERVER_PASSWORD="${SQLSERVER_PASSWORD:-${SA_PASSWORD:-}}"


EXCLUDE_CLAUSE=" EXCLUDING TABLE NAMES LIKE 'Language', '__EFMigrationsHistory' IN SCHEMA 'dbo'"

echo ""
echo "============================================="
echo "  SQL Server → PostgreSQL (BYO endpoint)"
echo "============================================="
echo ""
echo "  Source: $SQLSERVER_USER@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB"
echo "  Target: $PG_USER@$PG_HOST:$PG_PORT/$PG_DB"
echo ""

# ------------------------------------------------------------------
# Preflight: pgloader installed?
# ------------------------------------------------------------------
pgloader() {
  podman run --rm --network=host -v /tmp:/tmp -e TDSDUMP=/tmp/pgloader/freetds.log -e TDSVER=8.0 -e TDS_MAX_CONN=100 --name pgloader -i \
    docker.io/esbalo/pgloader:1.0.0 \
    pgloader "$@"
}

if ! command -v pgloader >/dev/null 2>&1; then
    cat >&2 <<EOF
ERROR: pgloader not found.

Install:
  Ubuntu/Debian:  sudo apt-get install -y pgloader
  macOS (brew):   brew install pgloader
  Docs:           https://pgloader.io
EOF
    exit 127
fi


# ------------------------------------------------------------------
# Generate pgloader config from template
# ------------------------------------------------------------------
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
PGLOADER_CONF="$TMP_DIR/migration.load"
export TDSVER=8.0

# Keep CamelCase identifiers and skip pgloader's sequence reset. pgloader's
# reset query can break when identifiers are quoted (e.g. ""Id"").
WITH_OPTIONS="include drop, create tables, create indexes, reset sequences, quote identifiers, preserve index names"

# SQL Server index names are table-scoped, while PostgreSQL index names are
# schema-scoped. Enable pgloader name uniquification only when needed.
if [ "$UNIQUIFY_INDEX_NAMES" = true ]; then
    WITH_OPTIONS="$WITH_OPTIONS, uniquify index names"
fi

if [ "$SCHEMA_ONLY" = true ]; then
    WITH_OPTIONS="$WITH_OPTIONS, schema only"
fi

# Ignore constraints created by EFCore, only focus on mapping the data into the correct table and colum names
if [ "$DATA_ONLY" = true ]; then
  WITH_OPTIONS="$WITH_OPTIONS, data only"
fi

# pgloader can emit invalid FK DDL for SQL Server schemas that reference
# alternate/composite keys; keep FK creation opt-in for the BYO flow.
if [ "$CREATE_FOREIGN_KEYS" = true ]; then
    WITH_OPTIONS="$WITH_OPTIONS, foreign keys"
else
    WITH_OPTIONS="$WITH_OPTIONS, no foreign keys"
fi

# URL-encode the SQL Server password (pgloader connection URI safe)
SQLSERVER_PASSWORD_ENC="$(printf '%s' "$SQLSERVER_PASSWORD" | sed -e 's/@/%40/g' -e 's/:/%3A/g' -e 's/\//%2F/g' -e 's/?/%3F/g' -e 's/#/%23/g' -e 's/!/%21/g')"
PG_PASSWORD_ENC="$(printf '%s' "$PG_PASSWORD" | sed -e 's/@/%40/g' -e 's/:/%3A/g' -e 's/\//%2F/g' -e 's/?/%3F/g' -e 's/#/%23/g' -e 's/!/%21/g')"


cat > "$PGLOADER_CONF" <<EOF
LOAD DATABASE
     FROM mssql://$SQLSERVER_USER:$SQLSERVER_PASSWORD_ENC@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB
     INTO postgresql://$PG_USER:$PG_PASSWORD_ENC@$PG_HOST:$PG_PORT/$PG_DB?sslmode=disable
     ALTER SCHEMA 'dbo' RENAME TO 'public'

 WITH $WITH_OPTIONS

$EXCLUDE_CLAUSE

 SET work_mem to '128MB',
     maintenance_work_mem to '512 MB',
     search_path to 'public'

 CAST type bit when (= 1 precision) to boolean drop typemod,
      type uniqueidentifier to uuid drop typemod,
      type varchar to "character varying" keep typemod,
      type nvarchar when (= precision 256) to "character varying" keep typemod,
      type nvarchar to text drop typemod,
      type nchar to "character varying" keep typemod,
      type datetime2 to timestamptz drop typemod,
      type datetimeoffset to timestamptz drop typemod,
      type money to numeric drop typemod,
      type smallmoney to numeric drop typemod,
      type tinyint to smallint drop typemod,
      type hierarchyid to "character varying" drop typemod,
      type geography to "character varying" drop typemod,
      type geometry to "character varying" drop typemod,
      type int with extra auto_increment to serial drop typemod
;
EOF

# ------------------------------------------------------------------
# Run
# ------------------------------------------------------------------
if [ "$DRY_RUN" = true ]; then
    echo "[1/2] pgloader dry-run (validation only)..."
    pgloader --dry-run "$PGLOADER_CONF"
    echo ""
    echo "Dry-run complete. Re-run without --dry-run to perform the migration."
    exit 0
fi

TOTAL_STEPS=1
if [ "$SCHEMA_ONLY" = false ]; then
    TOTAL_STEPS=2
fi

echo "[1/$TOTAL_STEPS] Running pgloader..."
pgloader "$PGLOADER_CONF"


echo "[$TOTAL_STEPS/$TOTAL_STEPS] Verifying target..."
PGPASSWORD="$PG_PASSWORD" psql \
    -v ON_ERROR_STOP=1 \
    -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
    -c "SELECT table_schema, COUNT(*) AS tables FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema') GROUP BY table_schema ORDER BY table_schema;"

echo ""
echo "============================================="
echo "  BYO Migration complete!"
echo "============================================="
echo ""
if [ "$CREATE_FOREIGN_KEYS" = true ]; then
    echo "  Foreign keys: requested via --with-foreign-keys"
else
    echo "  Foreign keys: skipped by default (safer for alternate/composite key schemas)"
fi
if [ "$UNIQUIFY_INDEX_NAMES" = true ]; then
    echo "  Index names: pgloader uniquified (idx_<oid>_<source_name>)"
else
    echo "  Index names: restoring EF-style PK_/IX_ names (removes idx_<oid>_ prefix)"
fi
echo ""
echo "  Next steps:"
echo "    1. Run pgtap tests:         pg_prove -d \"postgresql://$PG_USER@$PG_HOST/$PG_DB\" tests/pgtap/t/"
echo "    2. Run row-count compare:   psql ... -f tests/row-count-comparison/compare.sql"
echo "    3. Use the agent in Copilot Chat: /db-migrate"
echo ""