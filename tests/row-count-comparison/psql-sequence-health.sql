WITH sequence_bindings AS (
    SELECT
        seq_ns.nspname AS sequence_schema,
        seq_cls.relname AS sequence_name,
        tbl_ns.nspname AS table_schema,
        tbl_cls.relname AS table_name,
        att.attname AS column_name
    FROM pg_class AS seq_cls
    JOIN pg_namespace AS seq_ns
        ON seq_ns.oid = seq_cls.relnamespace
    JOIN pg_depend AS dep
        ON dep.objid = seq_cls.oid
       AND dep.deptype = 'a'
    JOIN pg_attrdef AS ad
        ON ad.oid = dep.refobjid
    JOIN pg_class AS tbl_cls
        ON tbl_cls.oid = ad.adrelid
    JOIN pg_namespace AS tbl_ns
        ON tbl_ns.oid = tbl_cls.relnamespace
    JOIN pg_attribute AS att
        ON att.attrelid = tbl_cls.oid
       AND att.attnum = ad.adnum
    WHERE seq_cls.relkind = 'S'
      AND tbl_ns.nspname NOT IN ('pg_catalog', 'information_schema')
)
SELECT
    sb.table_schema || '.' || sb.table_name AS table_name,
    sb.column_name,
    sb.sequence_schema || '.' || sb.sequence_name AS sequence_name,
    COALESCE(max_values.table_max_value, 0) AS table_max_value,
    COALESCE(pg_sequences.last_value, 0) AS sequence_last_value,
    CASE
        WHEN COALESCE(max_values.table_max_value, 0) > COALESCE(pg_sequences.last_value, 0) THEN 'BEHIND'
        ELSE 'OK'
    END AS status
FROM sequence_bindings AS sb
LEFT JOIN pg_sequences
    ON pg_sequences.schemaname = sb.sequence_schema
   AND pg_sequences.sequencename = sb.sequence_name
LEFT JOIN LATERAL (
    SELECT
        (xpath(
            '/row/max_value/text()',
            query_to_xml(
                format(
                    'SELECT MAX(%I) AS max_value FROM %I.%I',
                    sb.column_name,
                    sb.table_schema,
                    sb.table_name
                ),
                false,
                true,
                ''
            )
        ))[1]::text::bigint AS table_max_value
) AS max_values
    ON true
ORDER BY status DESC, table_name, column_name;
