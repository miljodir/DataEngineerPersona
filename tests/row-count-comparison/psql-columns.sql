SELECT
    c.table_schema || '.' || c.table_name AS table_name,
    c.column_name,
    c.data_type,
    COALESCE(c.udt_name, '') AS udt_name,
    COALESCE(c.character_maximum_length::text, '') AS character_maximum_length,
    COALESCE(c.numeric_precision::text, '') AS numeric_precision,
    COALESCE(c.numeric_scale::text, '') AS numeric_scale,
    COALESCE(c.datetime_precision::text, '') AS datetime_precision,
    c.is_nullable,
    CASE
        WHEN c.is_identity = 'YES' OR c.column_default LIKE 'nextval(%' THEN 'YES'
        ELSE 'NO'
    END AS is_identity,
    COALESCE(c.column_default, '') AS column_default
FROM information_schema.columns AS c
JOIN information_schema.tables AS t
    ON t.table_schema = c.table_schema
   AND t.table_name = c.table_name
WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND t.table_type = 'BASE TABLE'
ORDER BY c.table_schema, c.table_name, c.ordinal_position;
