DROP TABLE IF EXISTS migration_orphan_results;

CREATE TEMP TABLE migration_orphan_results (
    child_table text,
    parent_table text,
    constraint_name text,
    fk_columns text,
    referenced_columns text,
    orphan_count bigint
);

DO $$
DECLARE
    fk record;
    orphan_count bigint;
BEGIN
    FOR fk IN
        WITH fk_metadata AS (
            SELECT
                child_ns.nspname AS child_schema,
                child_t.relname AS child_table,
                parent_ns.nspname AS parent_schema,
                parent_t.relname AS parent_table,
                con.conname AS constraint_name,
                string_agg(child_a.attname, ', ' ORDER BY child_cols.ordinality) AS fk_columns,
                string_agg(parent_a.attname, ', ' ORDER BY child_cols.ordinality) AS referenced_columns,
                string_agg(
                    format('child.%I IS NOT NULL', child_a.attname),
                    ' AND '
                    ORDER BY child_cols.ordinality
                ) AS not_null_clause,
                string_agg(
                    format('child.%I = parent.%I', child_a.attname, parent_a.attname),
                    ' AND '
                    ORDER BY child_cols.ordinality
                ) AS join_clause
            FROM pg_constraint AS con
            JOIN pg_class AS child_t
                ON child_t.oid = con.conrelid
            JOIN pg_namespace AS child_ns
                ON child_ns.oid = child_t.relnamespace
            JOIN pg_class AS parent_t
                ON parent_t.oid = con.confrelid
            JOIN pg_namespace AS parent_ns
                ON parent_ns.oid = parent_t.relnamespace
            JOIN unnest(con.conkey) WITH ORDINALITY AS child_cols(attnum, ordinality)
                ON true
            JOIN unnest(con.confkey) WITH ORDINALITY AS parent_cols(attnum, ordinality)
                ON parent_cols.ordinality = child_cols.ordinality
            JOIN pg_attribute AS child_a
                ON child_a.attrelid = child_t.oid
               AND child_a.attnum = child_cols.attnum
            JOIN pg_attribute AS parent_a
                ON parent_a.attrelid = parent_t.oid
               AND parent_a.attnum = parent_cols.attnum
            WHERE con.contype = 'f'
              AND child_ns.nspname NOT IN ('pg_catalog', 'information_schema')
              AND parent_ns.nspname NOT IN ('pg_catalog', 'information_schema')
            GROUP BY child_ns.nspname, child_t.relname, parent_ns.nspname, parent_t.relname, con.conname
        )
        SELECT *
        FROM fk_metadata
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I AS child WHERE %s AND NOT EXISTS (SELECT 1 FROM %I.%I AS parent WHERE %s)',
            fk.child_schema,
            fk.child_table,
            fk.not_null_clause,
            fk.parent_schema,
            fk.parent_table,
            fk.join_clause
        )
        INTO orphan_count;

        INSERT INTO migration_orphan_results (
            child_table,
            parent_table,
            constraint_name,
            fk_columns,
            referenced_columns,
            orphan_count
        )
        VALUES (
            fk.child_schema || '.' || fk.child_table,
            fk.parent_schema || '.' || fk.parent_table,
            fk.constraint_name,
            fk.fk_columns,
            fk.referenced_columns,
            orphan_count
        );
    END LOOP;
END $$;

SELECT
    child_table,
    parent_table,
    constraint_name,
    fk_columns,
    referenced_columns,
    orphan_count
FROM migration_orphan_results
ORDER BY orphan_count DESC, child_table, constraint_name;
