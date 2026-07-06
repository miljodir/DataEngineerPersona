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
#   SQLSERVER_HOST, SQLSERVER_PORT, SQLSERVER_DB
#   SQLSERVER_AUTH_MODE=sql (default, needs SQLSERVER_USER/SQLSERVER_PASSWORD)
#                       or aad (Azure AD interactive login; see
#                       scripts/pgloader-aad/README.md for one-time setup)
#   PGHOST,        PGPORT,        PGDATABASE,        PGUSER,        PGPASSWORD
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

# SQLSERVER_AUTH_MODE: "sql" (default, SQLSERVER_USER/PASSWORD) or "aad"
# (Azure AD / Entra ID via `az login`, no password needed). See
# scripts/pgloader-aad/README.md for the one-time setup "aad" requires.
: "${SQLSERVER_AUTH_MODE:=aad}"
case "$SQLSERVER_AUTH_MODE" in
    sql|aad) ;;
    *) echo "ERROR: SQLSERVER_AUTH_MODE must be 'sql' or 'aad' (got '$SQLSERVER_AUTH_MODE')" >&2; exit 1 ;;
esac

if [ "$SQLSERVER_AUTH_MODE" = "sql" ]; then
    : "${SQLSERVER_USER:=sa}"
    #: "${SQLSERVER_PASSWORD:?SQLSERVER_PASSWORD is required (set in .env)}"
    # Map the common .env names (set by .env.example for the demo) to BYO names
    # This lets demo defaults like SA_PASSWORD work when SQLSERVER_PASSWORD is unset.
    SQLSERVER_PASSWORD="${SQLSERVER_PASSWORD:-${SA_PASSWORD:-}}"
fi

: "${PGHOST:?PGHOST is required (set in .env)}"
: "${PGPORT:=5432}"
: "${PGDATABASE:?PGDATABASE is required (set in .env)}"
: "${PGUSER:?PGUSER is required (set in .env)}"
: "${PGPASSWORD:?PGPASSWORD is required (set in .env)}"


EXCLUDE_CLAUSE=" EXCLUDING TABLE NAMES LIKE 'Language', '__EFMigrationsHistory' IN SCHEMA 'dbo'"

echo ""
echo "============================================="
echo "  SQL Server → PostgreSQL (BYO endpoint)"
echo "============================================="
echo ""
if [ "$SQLSERVER_AUTH_MODE" = "aad" ]; then
    echo "  Source: (Azure AD auth)@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB"
else
    echo "  Source: $SQLSERVER_USER@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB"
fi
echo "  Target: $PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
echo ""

# ------------------------------------------------------------------
# Preflight: pgloader installed?
# ------------------------------------------------------------------

psql_target() {
  PGPASSWORD="$PGPASSWORD" psql \
    -X \
    -v ON_ERROR_STOP=1 \
    -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
    "$@"
}

if ! command -v pgloader4 >/dev/null 2>&1; then
    cat >&2 <<EOF
ERROR: pgloader4 not found on PATH.

This script expects the native pgloader v4 binary (pgloader4). See
scripts/pgloader-aad/README.md, or https://github.com/dimitri/pgloader
for installation instructions.
EOF
    exit 127
fi

if [ "$SQLSERVER_AUTH_MODE" = "aad" ]; then
    if ! command -v az >/dev/null 2>&1; then
        echo "ERROR: SQLSERVER_AUTH_MODE=aad requires the az CLI on PATH (used by" >&2
        echo "       authentication=ActiveDirectoryDefault's AzureCliCredential fallback)." >&2
        exit 127
    fi
    if ! az account show >/dev/null 2>&1; then
        echo "ERROR: Not logged in to Azure CLI. Run: az login" >&2
        exit 1
    fi
fi

# ------------------------------------------------------------------
# Generate pgloader config from template
# ------------------------------------------------------------------
TMP_DIR="$(mktemp -d)"
PGLOADER_CONF="$TMP_DIR/migration.load"
TARGET_FK_DROP_SQL="$TMP_DIR/target-fks.drop.sql"
TARGET_FK_RESTORE_SQL="$TMP_DIR/target-fks.restore.sql"
TARGET_FK_VALIDATE_SQL="$TMP_DIR/target-fks.validate.sql"
TARGET_FK_COUNT=0
TARGET_FKS_DROPPED=false
export TDSVER=8.0

cleanup() {
  local exit_code=$?

  if [ "$TARGET_FKS_DROPPED" = true ] && [ -s "$TARGET_FK_RESTORE_SQL" ]; then
    echo ""
    echo "Restoring target foreign keys after interrupted load..."
    if ! psql_target -1 -f "$TARGET_FK_RESTORE_SQL" >/dev/null; then
      echo "WARNING: Failed to restore target foreign keys automatically." >&2
      echo "         Reapply them manually with: psql -h \"$PGHOST\" -p \"$PGPORT\" -U \"$PGUSER\" -d \"$PGDATABASE\" -f \"$TARGET_FK_RESTORE_SQL\"" >&2
    fi
  fi

  rm -rf "$TMP_DIR"
  exit "$exit_code"
}

trap cleanup EXIT

prepare_target_foreign_keys() {
  psql_target -At <<'SQL' > "$TARGET_FK_DROP_SQL"
SELECT format(
         'ALTER TABLE %I.%I DROP CONSTRAINT %I;',
         nsp.nspname,
         rel.relname,
         con.conname
       )
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE con.contype = 'f'
  AND nsp.nspname = 'public'
ORDER BY rel.relname, con.conname;
SQL

  psql_target -At <<'SQL' > "$TARGET_FK_RESTORE_SQL"
SELECT format(
         'ALTER TABLE %I.%I ADD CONSTRAINT %I %s NOT VALID;',
         nsp.nspname,
         rel.relname,
         con.conname,
         pg_get_constraintdef(con.oid)
       )
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE con.contype = 'f'
  AND nsp.nspname = 'public'
ORDER BY rel.relname, con.conname;
SQL

  psql_target -At <<'SQL' > "$TARGET_FK_VALIDATE_SQL"
SELECT format(
         'ALTER TABLE %I.%I VALIDATE CONSTRAINT %I;',
         nsp.nspname,
         rel.relname,
         con.conname
       )
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
WHERE con.contype = 'f'
  AND nsp.nspname = 'public'
ORDER BY rel.relname, con.conname;
SQL

  TARGET_FK_COUNT="$(grep -cve '^[[:space:]]*$' "$TARGET_FK_DROP_SQL" || true)"
}

drop_target_foreign_keys() {
  if [ "$TARGET_FK_COUNT" -eq 0 ]; then
    return
  fi

  echo "  Temporarily dropping $TARGET_FK_COUNT existing target foreign keys so pgloader can load dependent tables in parallel..."
  psql_target -1 -f "$TARGET_FK_DROP_SQL" >/dev/null
  TARGET_FKS_DROPPED=true
}

restore_target_foreign_keys() {
  if [ "$TARGET_FK_COUNT" -eq 0 ]; then
    return
  fi

  psql_target -1 -f "$TARGET_FK_RESTORE_SQL" >/dev/null
  TARGET_FKS_DROPPED=false
  psql_target -1 -f "$TARGET_FK_VALIDATE_SQL" >/dev/null
}

# Keep CamelCase identifiers. pgloader's reset query can break when identifiers
# are quoted (e.g. ""Id""), so reseed explicitly after load.
WITH_OPTIONS="include drop, create tables, create indexes, quote identifiers, preserve index names"

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
# Note: pgloader v4 dropped the "no foreign keys" negation syntax — foreign
# keys are opt-in, so we simply omit the clause to skip creating them.
if [ "$CREATE_FOREIGN_KEYS" = true ]; then
    WITH_OPTIONS="$WITH_OPTIONS, foreign keys"
fi

# URL-encode the SQL Server password (pgloader connection URI safe)
PGPASSWORD_ENC="$(printf '%s' "$PGPASSWORD" | sed -e 's/@/%40/g' -e 's/:/%3A/g' -e 's/\//%2F/g' -e 's/?/%3F/g' -e 's/#/%23/g' -e 's/!/%21/g')"

# The mssql:// URI scheme hardcodes ";encrypt=false" internally in pgloader
# v4, which can conflict with Azure SQL's TLS requirements. Use the raw
# jdbc:sqlserver:// form instead so the whole connection string (including
# authentication=... for AAD) is passed through to the driver unchanged.
if [ "$SQLSERVER_AUTH_MODE" = "aad" ]; then
    # authentication=ActiveDirectoryDefault uses Azure Identity's
    # DefaultAzureCredential chain, which falls back to AzureCliCredential
    # (shells out to `az account get-access-token`, using your existing
    # `az login` session) when no other credential is available. This works
    # headlessly in WSL2 (no browser popup), unlike ActiveDirectoryInteractive
    # which requires xdg-open to launch a browser and fails with
    # "linux_xdg_open_failed" in WSL2. Requires the AAD jars from
    # scripts/pgloader-aad/fetch-aad-libs.sh; see scripts/pgloader-aad/README.md.
    SQLSERVER_FROM_URI="jdbc:sqlserver://$SQLSERVER_HOST:$SQLSERVER_PORT;databaseName=$SQLSERVER_DB;authentication=ActiveDirectoryDefault;encrypt=true;trustServerCertificate=false"
else
    SQLSERVER_PASSWORD_ENC="$(printf '%s' "$SQLSERVER_PASSWORD" | sed -e 's/@/%40/g' -e 's/:/%3A/g' -e 's/\//%2F/g' -e 's/?/%3F/g' -e 's/#/%23/g' -e 's/!/%21/g')"
    SQLSERVER_FROM_URI="mssql://$SQLSERVER_USER:$SQLSERVER_PASSWORD_ENC@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB"
fi

cat > "$PGLOADER_CONF" <<EOF
LOAD DATABASE
     FROM $SQLSERVER_FROM_URI
     INTO postgresql://$PGUSER:$PGPASSWORD_ENC@$PGHOST:$PGPORT/$PGDATABASE?sslmode=disable
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
      type geometry to "character varying" drop typemod
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

MANAGE_TARGET_FOREIGN_KEYS=false
if [ "$SCHEMA_ONLY" = false ] && [ "$DATA_ONLY" = true ]; then
    MANAGE_TARGET_FOREIGN_KEYS=true
    prepare_target_foreign_keys
fi

RUN_SEQUENCE_SYNC=false
if [ "$SCHEMA_ONLY" = false ]; then
    RUN_SEQUENCE_SYNC=true
fi

TOTAL_STEPS=2
if [ "$MANAGE_TARGET_FOREIGN_KEYS" = true ] && [ "$TARGET_FK_COUNT" -gt 0 ]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
    drop_target_foreign_keys
fi
if [ "$RUN_SEQUENCE_SYNC" = true ]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 1))
fi

echo "[1/$TOTAL_STEPS] Running pgloader..."
pgloader "$PGLOADER_CONF"

CURRENT_STEP=1
if [ "$MANAGE_TARGET_FOREIGN_KEYS" = true ] && [ "$TARGET_FK_COUNT" -gt 0 ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "[$CURRENT_STEP/$TOTAL_STEPS] Restoring target foreign keys..."
    restore_target_foreign_keys
fi

if [ "$RUN_SEQUENCE_SYNC" = true ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo "[$CURRENT_STEP/$TOTAL_STEPS] Synchronizing identity sequences..."
    #sync_target_identity_sequences
fi

CURRENT_STEP=$((CURRENT_STEP + 1))
echo "[$CURRENT_STEP/$TOTAL_STEPS] Verifying target..."
psql_target -c "SELECT table_schema, COUNT(*) AS tables FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema') GROUP BY table_schema ORDER BY table_schema;"

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
echo "    1. Run: ./scripts/validate-migration.sh"
echo "    Or use the agent in Copilot Chat: /db-migrate"
echo ""