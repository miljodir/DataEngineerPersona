#!/usr/bin/env bash

pgloader_local_check() {
    if [[ -n "${PGLOADER_JAR:-}" ]]; then
        if [[ ! -f "$PGLOADER_JAR" || ! -r "$PGLOADER_JAR" ]]; then
            echo "ERROR: PGLOADER_JAR does not point to a readable pgloader v4 JAR." >&2
            return 1
        fi
        if ! command -v java >/dev/null 2>&1; then
            echo "ERROR: Java 21 or later is required to run PGLOADER_JAR." >&2
            return 127
        fi
    elif ! command -v pgloader4 >/dev/null 2>&1; then
        echo "ERROR: Install pgloader v4 and set PGLOADER_JAR or put pgloader4 on PATH." >&2
        return 127
    fi
}

pgloader_local_map_host() {
    local temp_dir="$1"
    local library="${PGLOADER_NSS_WRAPPER:-}"

    if [[ -z "${PGHOSTADDR:-}" || "$PGHOSTADDR" == "$PGHOST" ]]; then
        return
    fi
    if [[ "$PGHOST" == *[[:space:]#]* || "$PGHOSTADDR" == *[[:space:]#]* ]]; then
        echo "ERROR: PGHOST and PGHOSTADDR must not contain whitespace or '#'." >&2
        return 1
    fi

    if [[ -z "$library" ]] && command -v ldconfig >/dev/null 2>&1; then
        library="$(ldconfig -p 2>/dev/null | awk '$1 == "libnss_wrapper.so" && !found { found = $NF } END { print found }')"
    fi
    if [[ -z "$library" || ! -f "$library" || ! -r "$library" ]]; then
        echo "ERROR: Local pgloader needs libnss-wrapper to use PGHOSTADDR with PGHOST." >&2
        echo "       Install libnss-wrapper or set PGLOADER_NSS_WRAPPER to its library path." >&2
        return 1
    fi

    PGLOADER_NSS_WRAPPER="$library"
    PGLOADER_HOSTS_FILE="$temp_dir/pgloader-hosts"
    printf '%s %s\n' "$PGHOSTADDR" "$PGHOST" >"$PGLOADER_HOSTS_FILE"
}

pgloader_local_run() {
    pgloader_local_check || return
    local -a runner
    if [[ -n "${PGLOADER_JAR:-}" ]]; then
        runner=(java -jar "$PGLOADER_JAR")
    else
        runner=(pgloader4)
    fi

    if [[ -n "${PGLOADER_HOSTS_FILE:-}" ]]; then
        env "LD_PRELOAD=$PGLOADER_NSS_WRAPPER${LD_PRELOAD:+:$LD_PRELOAD}" \
            "NSS_WRAPPER_HOSTS=$PGLOADER_HOSTS_FILE" "${runner[@]}" "$@"
    else
        command "${runner[@]}" "$@"
    fi
}
