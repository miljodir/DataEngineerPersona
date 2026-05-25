DROP TABLE IF EXISTS migration_duplicate_results;

CREATE TEMP TABLE migration_duplicate_results (
    table_name text,
    object_name text,
    object_type text,
    key_columns text,
    duplicate_group_count bigint,
    duplicate_row_count bigint
);

DO $$
DECLARE
    idx record;
    duplicate_group_count bigint;
    duplicate_row_count bigint;
BEGIN
    FOR idx IN
        WITH unique_objects AS (
            SELECT
                n.nspname AS table_schema,
                t.relname AS table_name,
                i.relname AS object_name,
                CASE
                    WHEN ix.indisprimary THEN 'PRIMARY_KEY'
                    WHEN con.contype = 'u' THEN 'UNIQUE_CONSTRAINT'
                    ELSE 'UNIQUE_INDEX'
                END AS object_type,
                string_agg(
                    quote_ident(a.attname),
                    ', '
                    ORDER BY cols.ordinality
                ) FILTER (WHERE cols.ordinality <= ix.indnkeyatts AND cols.attnum > 0) AS key_columns_sql,
                string_agg(
                    a.attname,
                    ', '
                    ORDER BY cols.ordinality
                ) FILTER (WHERE cols.ordinality <= ix.indnkeyatts AND cols.attnum > 0) AS key_columns,
                string_agg(
                    format('%I IS NOT NULL', a.attname),
                    ' AND '
                    ORDER BY cols.ordinality
                ) FILTER (WHERE cols.ordinality <= ix.indnkeyatts AND cols.attnum > 0) AS not_null_clause,
                COALESCE(pg_get_expr(ix.indpred, ix.indrelid), '') AS filter_definition
            FROM pg_index AS ix
            JOIN pg_class AS t
                ON t.oid = ix.indrelid
            JOIN pg_class AS i
                ON i.oid = ix.indexrelid
            JOIN pg_namespace AS n
                ON n.oid = t.relnamespace
            LEFT JOIN pg_constraint AS con
                ON con.conindid = ix.indexrelid
               AND con.contype IN ('p', 'u')
            JOIN unnest(ix.indkey) WITH ORDINALITY AS cols(attnum, ordinality)
                ON true
            LEFT JOIN pg_attribute AS a
                ON a.attrelid = t.oid
               AND a.attnum = cols.attnum
            WHERE ix.indisunique
              AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
              AND n.nspname NOT LIKE 'pg_temp_%'
              AND n.nspname NOT LIKE 'pg_toast_temp_%'
              AND cols.attnum > 0
            GROUP BY
                n.nspname,
                t.relname,
                i.relname,
                ix.indexrelid,
                ix.indisprimary,
                con.contype,
                ix.indnkeyatts,
                ix.indpred,
                ix.indrelid
        )
        SELECT *
        FROM unique_objects
        WHERE key_columns_sql IS NOT NULL
    LOOP
        EXECUTE format(
            'SELECT COUNT(*), COALESCE(SUM(duplicate_count - 1), 0) FROM (SELECT %s, COUNT(*) AS duplicate_count FROM %I.%I WHERE %s GROUP BY %s HAVING COUNT(*) > 1) AS duplicates',
            idx.key_columns_sql,
            idx.table_schema,
            idx.table_name,
            CASE
                WHEN idx.filter_definition = '' THEN idx.not_null_clause
                ELSE idx.not_null_clause || ' AND (' || idx.filter_definition || ')'
            END,
            idx.key_columns_sql
        )
        INTO duplicate_group_count, duplicate_row_count;

        INSERT INTO migration_duplicate_results (
            table_name,
            object_name,
            object_type,
            key_columns,
            duplicate_group_count,
            duplicate_row_count
        )
        VALUES (
            idx.table_schema || '.' || idx.table_name,
            idx.object_name,
            idx.object_type,
            idx.key_columns,
            COALESCE(duplicate_group_count, 0),
            COALESCE(duplicate_row_count, 0)
        );
    END LOOP;
END $$;

SELECT
    table_name,
    object_name,
    object_type,
    key_columns,
    duplicate_group_count,
    duplicate_row_count
FROM migration_duplicate_results
ORDER BY duplicate_group_count DESC, duplicate_row_count DESC, table_name, object_name;
