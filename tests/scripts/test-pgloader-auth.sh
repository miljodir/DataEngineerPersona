#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/repo/scripts/lib" "$TEST_ROOT/repo/samples/wide-world-importers/migration-scripts" \
    "$TEST_ROOT/bin" "$TEST_ROOT/capture"
cp "$ROOT/scripts/migrate-endpoint.sh" "$ROOT/scripts/run-migration.sh" \
    "$ROOT/scripts/validate-migration.sh" "$TEST_ROOT/repo/scripts/"
cp "$ROOT/scripts/lib/"*.sh "$TEST_ROOT/repo/scripts/lib/"
cp "$ROOT/samples/wide-world-importers/migration-scripts/pgloader.load" \
    "$TEST_ROOT/repo/samples/wide-world-importers/migration-scripts/"

cat >"$TEST_ROOT/bin/pgloader4" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$MOCK_CAPTURE/args"
cp "${!#}" "$MOCK_CAPTURE/load"
EOF
cat >"$TEST_ROOT/bin/java" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$MOCK_CAPTURE/args"
cp "${!#}" "$MOCK_CAPTURE/load"
EOF
cat >"$TEST_ROOT/bin/az" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$MOCK_CAPTURE/az-args"
EOF
cat >"$TEST_ROOT/bin/podman" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" >"$MOCK_CAPTURE/args"
cp "${!#}" "$MOCK_CAPTURE/load"
EOF
cat >"$TEST_ROOT/bin/sqlfluff" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/bin/"*

export PATH="$TEST_ROOT/bin:$PATH"
export MOCK_CAPTURE="$TEST_ROOT/capture"
REPO="$TEST_ROOT/repo"

write_env() {
    local auth="$1" runtime="$2" jar="$3" hostaddr="$4"
    cat >"$REPO/.env" <<EOF
export SQLSERVER_HOST='source.example'
export SQLSERVER_PORT='1433'
export SQLSERVER_DB='example_db'
export SQLSERVER_AUTH_MODE='$auth'
export SQLSERVER_USER='example_user'
export SQLSERVER_PASSWORD='example_password'
export PGHOST='proxy.example'
export PGHOSTADDR='$hostaddr'
export PGPORT='5432'
export PGDATABASE='app'
export PGUSER='example_target_user'
export PGPASSWORD=''
export PGSSLMODE='verify-full'
export PGSSLROOTCERT=''
export PGLOADER_RUNTIME='$runtime'
export PGLOADER_JAR='$jar'
EOF
}

assert_contains() {
    if ! grep -F -- "$2" "$1" >/dev/null; then
        echo "Expected '$2' in $1" >&2
        exit 1
    fi
}

write_env aad local '' ''
bash "$REPO/scripts/migrate-endpoint.sh" --dry-run >"$TEST_ROOT/output" 2>&1
assert_contains "$MOCK_CAPTURE/load" 'authentication=ActiveDirectoryDefault;encrypt=true;trustServerCertificate=false'
assert_contains "$MOCK_CAPTURE/load" 'jdbc:postgresql://proxy.example:5432/app?user=example_target_user&sslmode=verify-full'
assert_contains "$MOCK_CAPTURE/az-args" 'account'
assert_contains "$MOCK_CAPTURE/args" '--dry-run'

touch "$TEST_ROOT/pgloader.jar"
write_env aad local "$TEST_ROOT/pgloader.jar" ''
bash "$REPO/scripts/migrate-endpoint.sh" --dry-run >"$TEST_ROOT/output" 2>&1
assert_contains "$MOCK_CAPTURE/args" '-jar'
assert_contains "$MOCK_CAPTURE/args" "$TEST_ROOT/pgloader.jar"

write_env aad podman '' ''
if bash "$REPO/scripts/migrate-endpoint.sh" --dry-run >"$TEST_ROOT/output" 2>&1; then
    echo "AAD with Podman unexpectedly succeeded" >&2
    exit 1
fi
assert_contains "$TEST_ROOT/output" 'requires PGLOADER_RUNTIME=local'

write_env sql podman '' '127.0.0.1'
bash "$REPO/scripts/migrate-endpoint.sh" --dry-run >"$TEST_ROOT/output" 2>&1
assert_contains "$MOCK_CAPTURE/args" '--add-host'
assert_contains "$MOCK_CAPTURE/args" 'proxy.example:127.0.0.1'
assert_contains "$MOCK_CAPTURE/load" 'mssql://'

write_env sql local '' ''
bash "$REPO/scripts/run-migration.sh" --dry-run >"$TEST_ROOT/output" 2>&1
assert_contains "$MOCK_CAPTURE/args" 'pgloader.load'

source "$ROOT/scripts/lib/pgloader-local.sh"
touch "$TEST_ROOT/libnss_wrapper.so"
PGHOST='proxy.example'
PGHOSTADDR='127.0.0.1'
PGLOADER_NSS_WRAPPER="$TEST_ROOT/libnss_wrapper.so"
pgloader_local_map_host "$TEST_ROOT"
assert_contains "$PGLOADER_HOSTS_FILE" '127.0.0.1 proxy.example'
PGLOADER_NSS_WRAPPER="$TEST_ROOT/missing-lib.so"
if pgloader_local_map_host "$TEST_ROOT" >"$TEST_ROOT/output" 2>&1; then
    echo "Missing libnss-wrapper unexpectedly succeeded" >&2
    exit 1
fi
assert_contains "$TEST_ROOT/output" 'needs libnss-wrapper'

write_env aad local '' ''
if bash "$REPO/scripts/validate-migration.sh" >"$TEST_ROOT/output" 2>&1; then
    echo "AAD validation unexpectedly succeeded" >&2
    exit 1
fi
assert_contains "$TEST_ROOT/output" 'supports SQL authentication only'

echo "pgloader authentication and runtime tests passed"
