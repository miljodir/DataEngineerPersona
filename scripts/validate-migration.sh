#!/usr/bin/env bash
# Validate the migration and generate a source vs target comparison report.
# Usage: ./scripts/validate-migration.sh [--database <name>] [--iteration <label>] [--connection-string <conninfo>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ITERATION="run-$(date +%Y%m%d-%H%M%S)"
CONNECTION_STRING=""
REPORT_FILE="$REPO_ROOT/docs/03-validation-report.md"
TMP_DIR="$(mktemp -d)"
KEY_SEPARATOR=$'\x1f'

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

parse_conn_string() {
    local conn="$1"
    local token key value

    for token in $conn; do
        key="${token%%=*}"
        value="${token#*=}"

        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        case "$key" in
            host|hostaddr)
                export PGHOST="$value"
                PGHOST="$value"
                ;;
            port)
                export PGPORT="$value"
                PGPORT="$value"
                ;;
            user|username)
                export PGUSER="$value"
                PGUSER="$value"
                ;;
            dbname|database)
                export PGDATABASE="$value"
                PGDATABASE="$value"
                DATABASE="$value"
                ;;
            password)
                export PGPASSWORD="$value"
                PGPASSWORD="$value"
                ;;
            sslmode)
                export PGSSLMODE="$value"
                ;;
        esac
    done
}

load_env() {
    if [[ -f "$REPO_ROOT/.env" ]]; then
        set -a
        # shellcheck disable=SC1091
        source "$REPO_ROOT/.env"
        set +a
    elif [[ -f "$REPO_ROOT/.env.example" ]]; then
        echo "  No .env found - using defaults from .env.example"
        set -a
        # shellcheck disable=SC1091
        source "$REPO_ROOT/.env.example"
        set +a
    else
        echo "ERROR: No .env or .env.example found. Copy .env.example to .env and edit it." >&2
        exit 1
    fi
}

resolve_connection_variables() {
    SQLSERVER_PASSWORD="${SQLSERVER_PASSWORD:-${SA_PASSWORD:-}}"
    PGPASSWORD="${PGPASSWORD:-${PGPASSWORD:-}}"

    : "${SQLSERVER_HOST:?SQLSERVER_HOST is required (set in .env)}"
    : "${SQLSERVER_PORT:=1433}"
    : "${SQLSERVER_DB:?SQLSERVER_DB is required (set in .env)}"
    : "${SQLSERVER_USER:=sa}"
    : "${SQLSERVER_PASSWORD:?SQLSERVER_PASSWORD is required (set in .env)}"

    : "${PGHOST:=127.0.0.1}"
    : "${PGPORT:=5432}"
    : "${PGUSER:?PGUSER is required (set in .env)}"
    : "${PGDATABASE:=wide_world_importers}"
    : "${PGPASSWORD:?PGPASSWORD is required (set in .env)}"

    DATABASE="${DATABASE:-$PGDATABASE}"
}

psql_target() {
    PGPASSWORD="$PGPASSWORD" psql \
        -X \
        -v ON_ERROR_STOP=1 \
        -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$DATABASE" \
        "$@"
}

run_psql_query() {
    local sql_file="$1"
    local output_file="$2"
    local error_file="$3"

    psql_target -A -F $'\t' -q -t -f "$sql_file" >"$output_file" 2>"$error_file"
}

sanitize_tsql_output() {
    sed \
        -e '/^locale is /d' \
        -e '/^using default charset /d' \
        -e '/^[[:space:]]*$/d'
}

run_tsql_query() {
    local sql_file="$1"
    local output_file="$2"
    local error_file="$3"
    local raw_output="$output_file.raw"
    local rc=0

    set +e
    TDSVER="${TDSVER:-7.4}" tsql \
        -H "$SQLSERVER_HOST" -p "$SQLSERVER_PORT" \
        -U "$SQLSERVER_USER" -P "$SQLSERVER_PASSWORD" \
        -D "$SQLSERVER_DB" \
        -o hfq >"$raw_output" 2>"$error_file" < <(
            cat "$sql_file"
            printf '\ngo\n'
        )
    rc=$?
    set -e

    sanitize_tsql_output <"$raw_output" >"$output_file"
    rm -f "$raw_output"

    return "$rc"
}

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

normalize_qualified_name() {
    local value="$1"
    local schema object normalized_schema

    if [[ "$value" != *.* ]]; then
        printf '%s' "$value"
        return
    fi

    schema="${value%%.*}"
    object="${value#*.}"
    normalized_schema="$(to_lower "$schema")"

    if [[ "$normalized_schema" == "dbo" ]]; then
        normalized_schema="public"
    fi

    printf '%s.%s' "$normalized_schema" "$object"
}

md_escape() {
    local value="$1"
    value="${value//$'\r'/ }"
    value="${value//$'\n'/ }"
    value="${value//|/\\|}"
    printf '%s' "$value"
}

simple_type_compatible() {
    local source_type target_type

    source_type="$(to_lower "$(trim "$1")")"
    target_type="$(to_lower "$(trim "$2")")"

    case "$source_type" in
        bit)
            [[ "$target_type" == "boolean" ]]
            ;;
        uniqueidentifier)
            [[ "$target_type" == "uuid" ]]
            ;;
        varchar)
            [[ "$target_type" == "character varying" || "$target_type" == "text" ]]
            ;;
        nvarchar)
            [[ "$target_type" == "character varying" || "$target_type" == "text" ]]
            ;;
        nchar)
            [[ "$target_type" == "character varying" || "$target_type" == "character" ]]
            ;;
        char)
            [[ "$target_type" == "character" || "$target_type" == "character varying" ]]
            ;;
        datetime2 | datetimeoffset)
            [[ "$target_type" == "timestamp with time zone" ]]
            ;;
        datetime | smalldatetime)
            [[ "$target_type" == "timestamp without time zone" || "$target_type" == "timestamp with time zone" ]]
            ;;
        money | smallmoney | decimal | numeric)
            [[ "$target_type" == "numeric" ]]
            ;;
        tinyint)
            [[ "$target_type" == "smallint" ]]
            ;;
        float)
            [[ "$target_type" == "double precision" || "$target_type" == "real" ]]
            ;;
        real)
            [[ "$target_type" == "real" || "$target_type" == "double precision" ]]
            ;;
        int)
            [[ "$target_type" == "integer" ]]
            ;;
        bigint)
            [[ "$target_type" == "bigint" ]]
            ;;
        smallint)
            [[ "$target_type" == "smallint" ]]
            ;;
        date)
            [[ "$target_type" == "date" ]]
            ;;
        time)
            [[ "$target_type" == "time without time zone" || "$target_type" == "time with time zone" || "$target_type" == "time" ]]
            ;;
        text | ntext)
            [[ "$target_type" == "text" ]]
            ;;
        binary | varbinary | image | rowversion | timestamp)
            [[ "$target_type" == "bytea" ]]
            ;;
        xml)
            [[ "$target_type" == "xml" || "$target_type" == "text" ]]
            ;;
        hierarchyid | geography | geometry)
            [[ "$target_type" == "character varying" || "$target_type" == "text" ]]
            ;;
        *)
            [[ "$source_type" == "$target_type" ]]
            ;;
    esac
}

parameter_lists_compatible() {
    local source_list="$1"
    local target_list="$2"
    local -a source_types target_types
    local i

    if [[ -z "$source_list" && -z "$target_list" ]]; then
        return 0
    fi

    IFS=',' read -r -a source_types <<<"$source_list"
    IFS=',' read -r -a target_types <<<"$target_list"

    if [[ "${#source_types[@]}" -ne "${#target_types[@]}" ]]; then
        return 1
    fi

    for ((i = 0; i < ${#source_types[@]}; i++)); do
        if ! simple_type_compatible "${source_types[$i]}" "${target_types[$i]}"; then
            return 1
        fi
    done

    return 0
}

COLUMN_NOTE=""

column_mapping_compatible() {
    local source_type="$1"
    local source_char_len="$2"
    local source_precision="$3"
    local source_scale="$4"
    local source_nullable="$5"
    local source_identity="$6"
    local target_type="$7"
    local target_char_len="$8"
    local target_precision="$9"
    local target_scale="${10}"
    local target_nullable="${11}"
    local target_identity="${12}"
    local target_default="${13}"
    local source_type_norm target_type_norm type_note=""

    source_type_norm="$(to_lower "$(trim "$source_type")")"
    target_type_norm="$(to_lower "$(trim "$target_type")")"

    case "$source_type_norm" in
        bit)
            [[ "$target_type_norm" == "boolean" ]] || {
                COLUMN_NOTE="Expected pgloader cast bit -> boolean"
                return 1
            }
            type_note="Expected pgloader cast bit -> boolean"
            ;;
        uniqueidentifier)
            [[ "$target_type_norm" == "uuid" ]] || {
                COLUMN_NOTE="Expected pgloader cast uniqueidentifier -> uuid"
                return 1
            }
            type_note="Expected pgloader cast uniqueidentifier -> uuid"
            ;;
        varchar)
            if [[ "$source_char_len" == "-1" ]]; then
                [[ "$target_type_norm" == "character varying" || "$target_type_norm" == "text" ]] || {
                    COLUMN_NOTE="Expected varchar(max) -> character varying/text"
                    return 1
                }
                type_note="Expected pgloader cast varchar(max) -> character varying/text"
            else
                [[ "$target_type_norm" == "character varying" ]] || {
                    COLUMN_NOTE="Expected pgloader cast varchar -> character varying"
                    return 1
                }
                if [[ -n "$target_char_len" && "$target_char_len" != "$source_char_len" ]]; then
                    COLUMN_NOTE="Character length differs ($source_char_len -> $target_char_len)"
                    return 1
                fi
                type_note="Expected pgloader cast varchar -> character varying"
            fi
            ;;
        nvarchar)
            if [[ "$source_char_len" == "256" ]]; then
                [[ "$target_type_norm" == "character varying" ]] || {
                    COLUMN_NOTE="Expected pgloader cast nvarchar(256) -> character varying"
                    return 1
                }
                if [[ -n "$target_char_len" && "$target_char_len" != "256" ]]; then
                    COLUMN_NOTE="Character length differs (256 -> $target_char_len)"
                    return 1
                fi
                type_note="Expected pgloader cast nvarchar(256) -> character varying"
            else
                [[ "$target_type_norm" == "text" ]] || {
                    COLUMN_NOTE="Expected pgloader cast nvarchar -> text"
                    return 1
                }
                type_note="Expected pgloader cast nvarchar -> text"
            fi
            ;;
        nchar)
            [[ "$target_type_norm" == "character varying" || "$target_type_norm" == "character" ]] || {
                COLUMN_NOTE="Expected pgloader cast nchar -> character varying"
                return 1
            }
            if [[ -n "$source_char_len" && -n "$target_char_len" && "$source_char_len" != "$target_char_len" ]]; then
                COLUMN_NOTE="Character length differs ($source_char_len -> $target_char_len)"
                return 1
            fi
            type_note="Expected pgloader cast nchar -> character varying"
            ;;
        datetime2 | datetimeoffset)
            [[ "$target_type_norm" == "timestamp with time zone" ]] || {
                COLUMN_NOTE="Expected pgloader cast $source_type_norm -> timestamp with time zone"
                return 1
            }
            type_note="Expected pgloader cast $source_type_norm -> timestamp with time zone"
            ;;
        money | smallmoney)
            [[ "$target_type_norm" == "numeric" ]] || {
                COLUMN_NOTE="Expected pgloader cast $source_type_norm -> numeric"
                return 1
            }
            type_note="Expected pgloader cast $source_type_norm -> numeric"
            ;;
        tinyint)
            [[ "$target_type_norm" == "smallint" ]] || {
                COLUMN_NOTE="Expected pgloader cast tinyint -> smallint"
                return 1
            }
            type_note="Expected pgloader cast tinyint -> smallint"
            ;;
        hierarchyid | geography | geometry)
            [[ "$target_type_norm" == "character varying" || "$target_type_norm" == "text" ]] || {
                COLUMN_NOTE="Expected pgloader cast $source_type_norm -> character varying"
                return 1
            }
            type_note="Expected pgloader cast $source_type_norm -> character varying"
            ;;
        int)
            [[ "$target_type_norm" == "integer" ]] || {
                COLUMN_NOTE="Expected int -> integer"
                return 1
            }
            if [[ "$source_identity" == "YES" ]]; then
                if [[ "$target_identity" != "YES" && "$target_default" != nextval\(* ]]; then
                    COLUMN_NOTE="Expected identity column to land as integer with sequence/default"
                    return 1
                fi
                type_note="Expected pgloader cast int identity -> serial-backed integer"
            else
                type_note="Expected int -> integer"
            fi
            ;;
        bigint)
            [[ "$target_type_norm" == "bigint" ]] || {
                COLUMN_NOTE="Expected bigint -> bigint"
                return 1
            }
            type_note="Expected bigint -> bigint"
            ;;
        smallint)
            [[ "$target_type_norm" == "smallint" ]] || {
                COLUMN_NOTE="Expected smallint -> smallint"
                return 1
            }
            type_note="Expected smallint -> smallint"
            ;;
        decimal | numeric)
            [[ "$target_type_norm" == "numeric" ]] || {
                COLUMN_NOTE="Expected $source_type_norm -> numeric"
                return 1
            }
            if [[ -n "$source_precision" && -n "$target_precision" && "$source_precision" != "$target_precision" ]]; then
                COLUMN_NOTE="Numeric precision differs ($source_precision -> $target_precision)"
                return 1
            fi
            if [[ -n "$source_scale" && -n "$target_scale" && "$source_scale" != "$target_scale" ]]; then
                COLUMN_NOTE="Numeric scale differs ($source_scale -> $target_scale)"
                return 1
            fi
            type_note="Expected $source_type_norm -> numeric"
            ;;
        float)
            [[ "$target_type_norm" == "double precision" || "$target_type_norm" == "real" ]] || {
                COLUMN_NOTE="Expected float -> double precision"
                return 1
            }
            type_note="Expected float -> double precision"
            ;;
        real)
            [[ "$target_type_norm" == "real" || "$target_type_norm" == "double precision" ]] || {
                COLUMN_NOTE="Expected real -> real"
                return 1
            }
            type_note="Expected real -> real"
            ;;
        date)
            [[ "$target_type_norm" == "date" ]] || {
                COLUMN_NOTE="Expected date -> date"
                return 1
            }
            type_note="Expected date -> date"
            ;;
        time)
            [[ "$target_type_norm" == "time without time zone" || "$target_type_norm" == "time with time zone" || "$target_type_norm" == "time" ]] || {
                COLUMN_NOTE="Expected time -> time"
                return 1
            }
            type_note="Expected time -> time"
            ;;
        datetime | smalldatetime)
            [[ "$target_type_norm" == "timestamp without time zone" || "$target_type_norm" == "timestamp with time zone" ]] || {
                COLUMN_NOTE="Expected $source_type_norm -> timestamp"
                return 1
            }
            type_note="Expected $source_type_norm -> timestamp"
            ;;
        char)
            [[ "$target_type_norm" == "character" || "$target_type_norm" == "character varying" ]] || {
                COLUMN_NOTE="Expected char -> character/character varying"
                return 1
            }
            if [[ -n "$source_char_len" && -n "$target_char_len" && "$source_char_len" != "$target_char_len" ]]; then
                COLUMN_NOTE="Character length differs ($source_char_len -> $target_char_len)"
                return 1
            fi
            type_note="Expected char -> character"
            ;;
        text | ntext)
            [[ "$target_type_norm" == "text" ]] || {
                COLUMN_NOTE="Expected $source_type_norm -> text"
                return 1
            }
            type_note="Expected $source_type_norm -> text"
            ;;
        binary | varbinary | image | rowversion | timestamp)
            [[ "$target_type_norm" == "bytea" ]] || {
                COLUMN_NOTE="Expected $source_type_norm -> bytea"
                return 1
            }
            type_note="Expected $source_type_norm -> bytea"
            ;;
        xml)
            [[ "$target_type_norm" == "xml" || "$target_type_norm" == "text" ]] || {
                COLUMN_NOTE="Expected xml -> xml/text"
                return 1
            }
            type_note="Expected xml -> xml/text"
            ;;
        *)
            simple_type_compatible "$source_type_norm" "$target_type_norm" || {
                COLUMN_NOTE="No compatible mapping rule for $source_type -> $target_type"
                return 1
            }
            type_note="Compatible pass-through type"
            ;;
    esac

    if [[ "$source_nullable" != "$target_nullable" ]]; then
        COLUMN_NOTE="$type_note; nullability differs ($source_nullable -> $target_nullable)"
        return 1
    fi

    COLUMN_NOTE="$type_note"
    return 0
}

write_query_failure_report() {
    local source_error_file="$1"
    local target_error_file="$2"

    {
        echo "# Phase 3: Validation Report"
        echo
        echo "Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')  "
        echo "Iteration: $ITERATION  "
        echo "Source database: \`$SQLSERVER_DB\` on \`$SQLSERVER_HOST:$SQLSERVER_PORT\`  "
        echo "Target database: \`$DATABASE\` on \`$PGHOST:$PGPORT\`"
        echo
        echo "## Validation Summary"
        echo
        echo "| Area | Status | Differences | Notes |"
        echo "|---|---|---:|---|"
        echo "| Runtime connectivity | ❌ | 1 | Unable to collect comparison datasets from one or both databases |"
        echo
        echo "## Query Failures"
        echo
        echo "| Endpoint | Error excerpt |"
        echo "|---|---|"
        printf '| SQL Server | %s |\n' "$(md_escape "$(head -n 5 "$source_error_file" 2>/dev/null | tr '\n' ' ')")"
        printf '| PostgreSQL | %s |\n' "$(md_escape "$(head -n 5 "$target_error_file" 2>/dev/null | tr '\n' ' ')")"
        echo
        echo "## Next Review Step"
        echo
        echo "Fix the reported connectivity/query errors, then re-run \`scripts/validate-migration.sh\` to regenerate the comparison tables."
    } >"$REPORT_FILE"
}

write_rows_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-rows.tsv"
    local target_file="$TMP_DIR/target-rows.tsv"
    local -A source_counts=() source_labels=() target_counts=() target_labels=()
    local total=0
    local mismatches=0
    local status="✅"
    local table_name row_count key label note row_status

    while IFS=$'\t' read -r table_name row_count; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")"
        source_counts["$key"]="$row_count"
        source_labels["$key"]="$table_name"
    done <"$source_file"

    while IFS=$'\t' read -r table_name row_count; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")"
        target_counts["$key"]="$row_count"
        target_labels["$key"]="$table_name"
    done <"$target_file"

    {
        echo "## Row counts"
        echo
        echo "| Status | Table | SQL Server rows | PostgreSQL rows | Detail |"
        echo "|---|---|---:|---:|---|"

        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            total=$((total + 1))
            label="${source_labels[$key]:-${target_labels[$key]}}"
            row_count="${source_counts[$key]:-}"
            local target_count="${target_counts[$key]:-}"

            if [[ -z "$row_count" ]]; then
                row_status="❌"
                note="Missing from SQL Server results"
                mismatches=$((mismatches + 1))
            elif [[ -z "$target_count" ]]; then
                row_status="❌"
                note="Missing from PostgreSQL results"
                mismatches=$((mismatches + 1))
            elif [[ "$row_count" == "$target_count" ]]; then
                row_status="✅"
                note="Exact COUNT(*) match"
            else
                row_status="❌"
                note="Row count mismatch"
                mismatches=$((mismatches + 1))
            fi

            printf '| %s | `%s` | %s | %s | %s |\n' \
                "$row_status" \
                "$(md_escape "$label")" \
                "${row_count:-n/a}" \
                "${target_count:-n/a}" \
                "$(md_escape "$note")"
        done < <(
            {
                printf '%s\n' "${!source_counts[@]}"
                printf '%s\n' "${!target_counts[@]}"
            } | awk 'NF && !seen[$0]++' | sort
        )

        if [[ "$total" -eq 0 ]]; then
            echo "| N/A | n/a | n/a | n/a | No user tables returned by either query |"
        fi

        echo
    } >>"$report_sections"

    if [[ "$mismatches" -gt 0 ]]; then
        status="❌"
    fi

    printf '| Row counts | %s | %d | Exact `COUNT(*)` comparison across user tables |\n' "$status" "$mismatches"
}

write_primary_key_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-primary-keys.tsv"
    local target_file="$TMP_DIR/target-primary-keys.tsv"
    local -A source_constraints=() source_columns=() source_labels=()
    local -A target_constraints=() target_columns=() target_labels=()
    local mismatches=0
    local total=0
    local status="✅"
    local table_name constraint_name key_columns key label note row_status

    while IFS=$'\t' read -r table_name constraint_name key_columns; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")"
        source_constraints["$key"]="$constraint_name"
        source_columns["$key"]="$key_columns"
        source_labels["$key"]="$table_name"
    done <"$source_file"

    while IFS=$'\t' read -r table_name constraint_name key_columns; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")"
        target_constraints["$key"]="$constraint_name"
        target_columns["$key"]="$key_columns"
        target_labels["$key"]="$table_name"
    done <"$target_file"

    {
        echo "## Primary keys"
        echo
        echo "| Status | Table | SQL Server PK | PostgreSQL PK | Detail |"
        echo "|---|---|---|---|---|"

        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            total=$((total + 1))
            label="${source_labels[$key]:-${target_labels[$key]}}"

            if [[ -z "${source_columns[$key]:-}" ]]; then
                row_status="❌"
                note="Primary key only present on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif [[ -z "${target_columns[$key]:-}" ]]; then
                row_status="❌"
                note="Primary key missing on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif [[ "${source_columns[$key]}" == "${target_columns[$key]}" ]]; then
                row_status="✅"
                note="Ordered PK columns match"
            else
                row_status="❌"
                note="Ordered PK columns differ"
                mismatches=$((mismatches + 1))
            fi

            printf '| %s | `%s` | `%s` | `%s` | %s |\n' \
                "$row_status" \
                "$(md_escape "$label")" \
                "$(md_escape "${source_columns[$key]:-n/a}")" \
                "$(md_escape "${target_columns[$key]:-n/a}")" \
                "$(md_escape "$note")"
        done < <(
            {
                printf '%s\n' "${!source_columns[@]}"
                printf '%s\n' "${!target_columns[@]}"
            } | awk 'NF && !seen[$0]++' | sort
        )

        if [[ "$total" -eq 0 ]]; then
            echo "| N/A | n/a | n/a | n/a | No user primary keys returned by either query |"
        fi

        echo
    } >>"$report_sections"

    if [[ "$mismatches" -gt 0 ]]; then
        status="❌"
    fi

    printf "| Primary keys | %s | %d | Compares each table's ordered PK columns and ignores constraint-name drift |\n" "$status" "$mismatches"
}

write_foreign_key_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-foreign-keys.tsv"
    local target_file="$TMP_DIR/target-foreign-keys.tsv"
    local -A source_table=() source_columns=() source_ref_table=() source_ref_columns=()
    local -A target_table=() target_columns=() target_ref_table=() target_ref_columns=()
    local source_count=0
    local target_count=0
    local mismatches=0
    local total=0
    local status="✅"
    local table_name constraint_name key_columns referenced_table referenced_columns key note row_status

    while IFS=$'\t' read -r table_name constraint_name key_columns referenced_table referenced_columns; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")${KEY_SEPARATOR}$key_columns${KEY_SEPARATOR}$(normalize_qualified_name "$referenced_table")${KEY_SEPARATOR}$referenced_columns"
        source_table["$key"]="$table_name"
        source_columns["$key"]="$key_columns"
        source_ref_table["$key"]="$referenced_table"
        source_ref_columns["$key"]="$referenced_columns"
        source_count=$((source_count + 1))
    done <"$source_file"

    while IFS=$'\t' read -r table_name constraint_name key_columns referenced_table referenced_columns; do
        [[ -z "${table_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")${KEY_SEPARATOR}$key_columns${KEY_SEPARATOR}$(normalize_qualified_name "$referenced_table")${KEY_SEPARATOR}$referenced_columns"
        target_table["$key"]="$table_name"
        target_columns["$key"]="$key_columns"
        target_ref_table["$key"]="$referenced_table"
        target_ref_columns["$key"]="$referenced_columns"
        target_count=$((target_count + 1))
    done <"$target_file"

    {
        echo "## Foreign keys"
        echo

        if [[ "$source_count" -gt 0 && "$target_count" -eq 0 ]]; then
            echo "`scripts/migrate-endpoint.sh` defaults to `no foreign keys`, so no PostgreSQL foreign keys were found to compare."
            echo
            echo "| Status | SQL Server FKs | PostgreSQL FKs | Guidance |"
            echo "|---|---:|---:|---|"
            printf '| N/A | %d | %d | Re-run the migration with `--with-foreign-keys` or apply FKs separately before using this section as a strict parity check. |\n' "$source_count" "$target_count"
            echo
            status="N/A"
        else
            echo "| Status | Child table | SQL Server relationship | PostgreSQL relationship | Detail |"
            echo "|---|---|---|---|---|"

            while IFS= read -r key; do
                [[ -z "$key" ]] && continue
                total=$((total + 1))

                if [[ -z "${source_table[$key]:-}" ]]; then
                    row_status="❌"
                    note="Foreign key only present on PostgreSQL"
                    mismatches=$((mismatches + 1))
                elif [[ -z "${target_table[$key]:-}" ]]; then
                    row_status="❌"
                    note="Foreign key missing on PostgreSQL"
                    mismatches=$((mismatches + 1))
                else
                    row_status="✅"
                    note="Relationship signature matches"
                fi

                printf '| %s | `%s` | `%s (%s) -> %s (%s)` | `%s (%s) -> %s (%s)` | %s |\n' \
                    "$row_status" \
                    "$(md_escape "${source_table[$key]:-${target_table[$key]}}")" \
                    "$(md_escape "${source_table[$key]:-n/a}")" \
                    "$(md_escape "${source_columns[$key]:-n/a}")" \
                    "$(md_escape "${source_ref_table[$key]:-n/a}")" \
                    "$(md_escape "${source_ref_columns[$key]:-n/a}")" \
                    "$(md_escape "${target_table[$key]:-n/a}")" \
                    "$(md_escape "${target_columns[$key]:-n/a}")" \
                    "$(md_escape "${target_ref_table[$key]:-n/a}")" \
                    "$(md_escape "${target_ref_columns[$key]:-n/a}")" \
                    "$(md_escape "$note")"
            done < <(
                {
                    printf '%s\n' "${!source_table[@]}"
                    printf '%s\n' "${!target_table[@]}"
                } | awk 'NF && !seen[$0]++' | sort
            )

            if [[ "$total" -eq 0 ]]; then
                echo "| N/A | n/a | n/a | n/a | No user foreign keys returned by either query |"
                status="N/A"
            elif [[ "$mismatches" -gt 0 ]]; then
                status="❌"
            fi

            echo
        fi
    } >>"$report_sections"

    if [[ "$status" == "N/A" ]]; then
        printf '| Foreign keys | %s | 0 | Skipped as a strict parity gate when PostgreSQL has no foreign keys, which is the default pgloader path in `migrate-endpoint.sh` |\n' "$status"
    else
        printf '| Foreign keys | %s | %d | Compares FK relationship signatures and ignores constraint-name drift |\n' "$status" "$mismatches"
    fi
}

write_view_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-views.tsv"
    local target_file="$TMP_DIR/target-views.tsv"
    local -A source_columns=() source_labels=() target_columns=() target_labels=()
    local source_count=0
    local target_count=0
    local mismatches=0
    local total=0
    local status="✅"
    local view_name column_list key note row_status

    while IFS=$'\t' read -r view_name column_list; do
        [[ -z "${view_name:-}" ]] && continue
        key="$(normalize_qualified_name "$view_name")"
        source_columns["$key"]="$column_list"
        source_labels["$key"]="$view_name"
        source_count=$((source_count + 1))
    done <"$source_file"

    while IFS=$'\t' read -r view_name column_list; do
        [[ -z "${view_name:-}" ]] && continue
        key="$(normalize_qualified_name "$view_name")"
        target_columns["$key"]="$column_list"
        target_labels["$key"]="$view_name"
        target_count=$((target_count + 1))
    done <"$target_file"

    {
        echo "## Views"
        echo

        if [[ "$source_count" -gt 0 && "$target_count" -eq 0 ]]; then
            echo "No PostgreSQL views were found. That is expected after a `data only` migration because views are not created in that mode."
            echo
            echo "| Status | SQL Server views | PostgreSQL views | Guidance |"
            echo "|---|---:|---:|---|"
            printf '| N/A | %d | %d | Run a schema phase that creates views before treating this section as a parity gate. |\n' "$source_count" "$target_count"
            echo
            status="N/A"
        else
            echo "| Status | View | SQL Server columns | PostgreSQL columns | Detail |"
            echo "|---|---|---|---|---|"

            while IFS= read -r key; do
                [[ -z "$key" ]] && continue
                total=$((total + 1))

                if [[ -z "${source_columns[$key]:-}" ]]; then
                    row_status="❌"
                    note="View only present on PostgreSQL"
                    mismatches=$((mismatches + 1))
                elif [[ -z "${target_columns[$key]:-}" ]]; then
                    row_status="❌"
                    note="View missing on PostgreSQL"
                    mismatches=$((mismatches + 1))
                elif [[ "${source_columns[$key]}" == "${target_columns[$key]}" ]]; then
                    row_status="✅"
                    note="Projected column list matches"
                else
                    row_status="❌"
                    note="Projected column list differs"
                    mismatches=$((mismatches + 1))
                fi

                printf '| %s | `%s` | `%s` | `%s` | %s |\n' \
                    "$row_status" \
                    "$(md_escape "${source_labels[$key]:-${target_labels[$key]}}")" \
                    "$(md_escape "${source_columns[$key]:-n/a}")" \
                    "$(md_escape "${target_columns[$key]:-n/a}")" \
                    "$(md_escape "$note")"
            done < <(
                {
                    printf '%s\n' "${!source_columns[@]}"
                    printf '%s\n' "${!target_columns[@]}"
                } | awk 'NF && !seen[$0]++' | sort
            )

            if [[ "$total" -eq 0 ]]; then
                echo "| N/A | n/a | n/a | n/a | No user views returned by either query |"
                status="N/A"
            elif [[ "$mismatches" -gt 0 ]]; then
                status="❌"
            fi

            echo
        fi
    } >>"$report_sections"

    if [[ "$status" == "N/A" ]]; then
        printf '| Views | %s | 0 | Skipped as a strict parity gate when the PostgreSQL target has no views, which is expected after `data only` migration runs |\n' "$status"
    else
        printf '| Views | %s | %d | Compares view existence and projected column order |\n' "$status" "$mismatches"
    fi
}

write_function_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-functions.tsv"
    local target_file="$TMP_DIR/target-functions.tsv"
    local -A source_name=() source_params=() source_return=()
    local -A target_name=() target_params=() target_return=()
    local mismatches=0
    local total=0
    local status="✅"
    local routine_name parameter_count parameter_types return_type key note row_status

    while IFS=$'\t' read -r routine_name parameter_count parameter_types return_type; do
        [[ -z "${routine_name:-}" ]] && continue
        key="$(normalize_qualified_name "$routine_name")${KEY_SEPARATOR}$parameter_count"
        source_name["$key"]="$routine_name"
        source_params["$key"]="$parameter_types"
        source_return["$key"]="$return_type"
    done <"$source_file"

    while IFS=$'\t' read -r routine_name parameter_count parameter_types return_type; do
        [[ -z "${routine_name:-}" ]] && continue
        key="$(normalize_qualified_name "$routine_name")${KEY_SEPARATOR}$parameter_count"
        target_name["$key"]="$routine_name"
        target_params["$key"]="$parameter_types"
        target_return["$key"]="$return_type"
    done <"$target_file"

    {
        echo "## Functions"
        echo
        echo "| Status | Function | SQL Server signature | PostgreSQL signature | Detail |"
        echo "|---|---|---|---|---|"

        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            total=$((total + 1))

            if [[ -z "${source_name[$key]:-}" ]]; then
                row_status="❌"
                note="Function only present on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif [[ -z "${target_name[$key]:-}" ]]; then
                row_status="❌"
                note="Function missing on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif ! parameter_lists_compatible "${source_params[$key]}" "${target_params[$key]}"; then
                row_status="❌"
                note="Parameter types differ after mapping"
                mismatches=$((mismatches + 1))
            elif ! simple_type_compatible "${source_return[$key]}" "${target_return[$key]}"; then
                row_status="❌"
                note="Return type differs after mapping"
                mismatches=$((mismatches + 1))
            else
                row_status="✅"
                note="Parameter count and mapped types align"
            fi

            printf '| %s | `%s` | `%s -> %s` | `%s -> %s` | %s |\n' \
                "$row_status" \
                "$(md_escape "${source_name[$key]:-${target_name[$key]}}")" \
                "$(md_escape "${source_params[$key]:-no parameters}")" \
                "$(md_escape "${source_return[$key]:-n/a}")" \
                "$(md_escape "${target_params[$key]:-no parameters}")" \
                "$(md_escape "${target_return[$key]:-n/a}")" \
                "$(md_escape "$note")"
        done < <(
            {
                printf '%s\n' "${!source_name[@]}"
                printf '%s\n' "${!target_name[@]}"
            } | awk 'NF && !seen[$0]++' | sort
        )

        if [[ "$total" -eq 0 ]]; then
            echo "| N/A | n/a | n/a | n/a | No user-defined functions returned by either query |"
            status="N/A"
        elif [[ "$mismatches" -gt 0 ]]; then
            status="❌"
        fi

        echo
    } >>"$report_sections"

    printf '| Functions | %s | %d | Compares function name + parameter count and validates mapped parameter/return types |\n' "$status" "$mismatches"
}

write_column_section() {
    local report_sections="$1"
    local source_file="$TMP_DIR/source-columns.tsv"
    local target_file="$TMP_DIR/target-columns.tsv"
    local -A source_table=() source_column_name=() source_type=() source_char_len=() source_precision=() source_scale=() source_nullable=() source_identity=()
    local -A target_table=() target_column_name=() target_type=() target_char_len=() target_precision=() target_scale=() target_nullable=() target_identity=() target_default=()
    local mismatches=0
    local total=0
    local status="✅"
    local table_name column_name data_type char_len precision scale datetime_precision is_nullable is_identity column_default key note row_status label

    while IFS=$'\t' read -r table_name column_name data_type char_len precision scale datetime_precision is_nullable is_identity; do
        [[ -z "${table_name:-}" || -z "${column_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")${KEY_SEPARATOR}$column_name"
        source_table["$key"]="$table_name"
        source_column_name["$key"]="$column_name"
        source_type["$key"]="$data_type"
        source_char_len["$key"]="$char_len"
        source_precision["$key"]="$precision"
        source_scale["$key"]="$scale"
        source_nullable["$key"]="$is_nullable"
        source_identity["$key"]="$is_identity"
    done <"$source_file"

    while IFS=$'\t' read -r table_name column_name data_type _udt_name char_len precision scale datetime_precision is_nullable is_identity column_default; do
        [[ -z "${table_name:-}" || -z "${column_name:-}" ]] && continue
        key="$(normalize_qualified_name "$table_name")${KEY_SEPARATOR}$column_name"
        target_table["$key"]="$table_name"
        target_column_name["$key"]="$column_name"
        target_type["$key"]="$data_type"
        target_char_len["$key"]="$char_len"
        target_precision["$key"]="$precision"
        target_scale["$key"]="$scale"
        target_nullable["$key"]="$is_nullable"
        target_identity["$key"]="$is_identity"
        target_default["$key"]="$column_default"
    done <"$target_file"

    {
        echo "## Columns and data types"
        echo
        echo "| Status | Column | SQL Server type | PostgreSQL type | Detail |"
        echo "|---|---|---|---|---|"

        while IFS= read -r key; do
            [[ -z "$key" ]] && continue
            total=$((total + 1))
            label="${source_table[$key]:-${target_table[$key]}}.${source_column_name[$key]:-${target_column_name[$key]}}"

            if [[ -z "${source_type[$key]:-}" ]]; then
                row_status="❌"
                note="Column only present on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif [[ -z "${target_type[$key]:-}" ]]; then
                row_status="❌"
                note="Column missing on PostgreSQL"
                mismatches=$((mismatches + 1))
            elif column_mapping_compatible \
                "${source_type[$key]}" \
                "${source_char_len[$key]:-}" \
                "${source_precision[$key]:-}" \
                "${source_scale[$key]:-}" \
                "${source_nullable[$key]:-}" \
                "${source_identity[$key]:-}" \
                "${target_type[$key]}" \
                "${target_char_len[$key]:-}" \
                "${target_precision[$key]:-}" \
                "${target_scale[$key]:-}" \
                "${target_nullable[$key]:-}" \
                "${target_identity[$key]:-}" \
                "${target_default[$key]:-}"; then
                row_status="✅"
                note="$COLUMN_NOTE"
            else
                row_status="❌"
                note="$COLUMN_NOTE"
                mismatches=$((mismatches + 1))
            fi

            printf '| %s | `%s` | `%s` | `%s` | %s |\n' \
                "$row_status" \
                "$(md_escape "$label")" \
                "$(md_escape "${source_type[$key]:-n/a}")" \
                "$(md_escape "${target_type[$key]:-n/a}")" \
                "$(md_escape "$note")"
        done < <(
            {
                printf '%s\n' "${!source_type[@]}"
                printf '%s\n' "${!target_type[@]}"
            } | awk 'NF && !seen[$0]++' | sort
        )

        if [[ "$total" -eq 0 ]]; then
            echo "| N/A | n/a | n/a | n/a | No base-table columns returned by either query |"
            status="N/A"
        elif [[ "$mismatches" -gt 0 ]]; then
            status="❌"
        fi

        echo
    } >>"$report_sections"

    printf '| Columns/data types | %s | %d | Validates base-table columns against the pgloader mappings in `scripts/migrate-endpoint.sh` |\n' "$status" "$mismatches"
}

generate_validation_report() {
    local source_error_file="$TMP_DIR/source-errors.log"
    local target_error_file="$TMP_DIR/target-errors.log"
    local report_sections="$TMP_DIR/report-sections.md"
    local summary_rows="$TMP_DIR/summary-rows.md"
    local query_failed=0

    if ! command -v psql >/dev/null 2>&1; then
        printf 'psql was not found in PATH.\n' >"$target_error_file"
        query_failed=1
    fi

    if ! command -v tsql >/dev/null 2>&1; then
        printf 'tsql was not found in PATH.\n' >"$source_error_file"
        query_failed=1
    fi

    if [[ "$query_failed" -eq 0 ]]; then
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/compare-tsql.sql" "$TMP_DIR/source-rows.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/compare.sql" "$TMP_DIR/target-rows.tsv" "$target_error_file"; then
            query_failed=1
        fi
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/mssql-columns.sql" "$TMP_DIR/source-columns.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/psql-columns.sql" "$TMP_DIR/target-columns.tsv" "$target_error_file"; then
            query_failed=1
        fi
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/mssql-primary-keys.sql" "$TMP_DIR/source-primary-keys.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/psql-primary-keys.sql" "$TMP_DIR/target-primary-keys.tsv" "$target_error_file"; then
            query_failed=1
        fi
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/mssql-foreign-keys.sql" "$TMP_DIR/source-foreign-keys.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/psql-foreign-keys.sql" "$TMP_DIR/target-foreign-keys.tsv" "$target_error_file"; then
            query_failed=1
        fi
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/mssql-views.sql" "$TMP_DIR/source-views.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/psql-views.sql" "$TMP_DIR/target-views.tsv" "$target_error_file"; then
            query_failed=1
        fi
        if ! run_tsql_query "$REPO_ROOT/tests/row-count-comparison/mssql-functions.sql" "$TMP_DIR/source-functions.tsv" "$source_error_file"; then
            query_failed=1
        fi
        if ! run_psql_query "$REPO_ROOT/tests/row-count-comparison/psql-functions.sql" "$TMP_DIR/target-functions.tsv" "$target_error_file"; then
            query_failed=1
        fi
    fi

    if [[ "$query_failed" -ne 0 ]]; then
        write_query_failure_report "$source_error_file" "$target_error_file"
        return 1
    fi

    : >"$report_sections"
    : >"$summary_rows"

    write_rows_section "$report_sections" >>"$summary_rows"
    write_primary_key_section "$report_sections" >>"$summary_rows"
    write_foreign_key_section "$report_sections" >>"$summary_rows"
    write_view_section "$report_sections" >>"$summary_rows"
    write_function_section "$report_sections" >>"$summary_rows"
    write_column_section "$report_sections" >>"$summary_rows"

    {
        echo "# Phase 3: Validation Report"
        echo
        echo "Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')  "
        echo "Iteration: $ITERATION  "
        echo "Source database: \`$SQLSERVER_DB\` on \`$SQLSERVER_HOST:$SQLSERVER_PORT\`  "
        echo "Target database: \`$DATABASE\` on \`$PGHOST:$PGPORT\`"
        echo
        echo "## Validation Summary"
        echo
        echo "| Area | Status | Differences | Notes |"
        echo "|---|---|---:|---|"
        cat "$summary_rows"
        echo
        cat "$report_sections"
    } >"$REPORT_FILE"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --database)
            DATABASE="$2"
            shift 2
            ;;
        --iteration)
            ITERATION="$2"
            shift 2
            ;;
        --connection-string)
            CONNECTION_STRING="$2"
            shift 2
            ;;
        -h | --help)
            echo "Usage: $0 [--database <name>] [--iteration <label>] [--connection-string <conninfo>]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

cd "$REPO_ROOT"

load_env
resolve_connection_variables

if [[ -n "$CONNECTION_STRING" ]]; then
    parse_conn_string "$CONNECTION_STRING"
fi

PGPROVE_ARGS=(-d "$DATABASE")
[[ -n "${PGHOST:-}" ]] && PGPROVE_ARGS+=(-h "$PGHOST")
[[ -n "${PGPORT:-}" ]] && PGPROVE_ARGS+=(-p "$PGPORT")
[[ -n "${PGUSER:-}" ]] && PGPROVE_ARGS+=(-U "$PGUSER")

echo "=== Phase 3: Migration Validation ==="
echo "Source: $SQLSERVER_USER@$SQLSERVER_HOST:$SQLSERVER_PORT/$SQLSERVER_DB"
echo "Target: $PGUSER@$PGHOST:$PGPORT/$DATABASE"
echo "Iteration: $ITERATION"
echo "Report: $REPORT_FILE"
echo ""

if command -v PGprove &>/dev/null; then
    echo "[1/3] Running security tests..."
    PGprove "${PGPROVE_ARGS[@]}" tests/security/t/*.sql --verbose 2>&1
else
    echo "[1/3] PGprove not found - skipping security tests"
fi

echo "[2/3] Running performance tests..."
if [[ -f tests/performance/run-performance-tests.sh ]]; then
    bash tests/performance/run-performance-tests.sh "$DATABASE" "$ITERATION" 2>&1
else
    echo "  Performance test runner not found"
fi

echo "[3/3] Comparing source and target metadata..."
generate_validation_report

echo ""
echo "Validation complete."
echo "  Markdown report: $REPORT_FILE"
echo "  Performance JSON: tests/performance/results/$ITERATION.json"
