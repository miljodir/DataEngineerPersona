SELECT
    v.table_schema || '.' || v.table_name AS view_name,
    COALESCE(
        string_agg(c.column_name, ', ' ORDER BY c.ordinal_position),
        ''
    ) AS view_columns
FROM information_schema.views AS v
LEFT JOIN information_schema.columns AS c
    ON c.table_schema = v.table_schema
   AND c.table_name = v.table_name
WHERE v.table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY v.table_schema, v.table_name
ORDER BY view_name;
