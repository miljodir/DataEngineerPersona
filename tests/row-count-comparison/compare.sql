SELECT
    table_schema || '.' || table_name AS table_name,
    (xpath(
        '/row/c/text()',
        query_to_xml(
            format('SELECT count(*) AS c FROM %I.%I', table_schema, table_name),
            false,
            true,
            ''
        )
    ))[1]::text::bigint AS row_count
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
